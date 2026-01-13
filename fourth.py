import os
import sys
import time
import threading
import queue
import logging
import pygame
import serial
from serial import SerialException

# ---------------------------
# Configuration
# ---------------------------
IMG_DIR = "/Users/jacobschneiderman/C++"
TITLE_IMG_CHESS = os.path.join(IMG_DIR, "CHESS.png")
TITLE_IMG_GAME = os.path.join(IMG_DIR, "GAME.png")

SERIAL_PORT = "/dev/cu.usbmodem14201"
BAUDRATE = 57600

SQUARES = 8
BOARD_PX = 640
SQUARE_PX = BOARD_PX // SQUARES

SIDE_COLS = 4
SIDE_PX = SIDE_COLS * SQUARE_PX

BEZEL_THICKNESS = SQUARE_PX // 4

WINDOW_WIDTH = BOARD_PX + SIDE_PX + 2 * BEZEL_THICKNESS
WINDOW_HEIGHT = BOARD_PX + 2 * BEZEL_THICKNESS

FPS = 60

# ---------------------------
# Colors
# ---------------------------
COLOR_GREY = (195, 135, 94)
COLOR_BLACK = (239, 224, 187)
COLOR_BG = (30, 30, 30)
COLOR_OPTION = (160, 160, 160)
COLOR_PANEL = (39, 39, 39)
COLOR_CHECKMATE = (178, 34, 34)

# ---------------------------
# Piece images
# ---------------------------
IMAGE_MAP = {
    ('b','k'): 'bk.png', ('b','n'): 'bn.png', ('b','p'): 'bp.png',
    ('b','b'): 'bb.png', ('b','q'): 'bq.png', ('b','r'): 'br.png',
    ('w','k'): 'wk.png', ('w','n'): 'wn.png', ('w','p'): 'wp.png',
    ('w','b'): 'wb.png', ('w','q'): 'wq.png', ('w','r'): 'wr.png',
}

# Promo locations (out-of-board squares)
PROMO_LOCS = [0x08, 0x09, 0x0A, 0x0B]

# ---------------------------
# Logging
# ---------------------------
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s %(levelname)s: %(message)s')

# ---------------------------
# Decoders
# ---------------------------
def decode_piece_bits(bitstr):
    if len(bitstr) != 8 or any(c not in '01' for c in bitstr):
        return None

    has_piece = bitstr[0] == '1'
    color = 'b' if bitstr[1] == '1' else 'w'
    option = bitstr[2] == '1'
    king_bit = bitstr[4] == '1'
    type_bits = bitstr[5:8]

    # Checkmate override: last four bits all 1
    if type_bits == '111':
        return {'checkmate': True, 'color': color, 'option': option}

    piece_type = None
    if king_bit:
        piece_type = 'k'
    else:
        piece_type = {
            '100': 'r', '010': 'b', '110': 'q', '001': 'n', '000': 'p'
        }.get(type_bits)

    if not has_piece:
        return {'has_piece': False, 'option': option}

    return {'has_piece': True, 'color': color, 'type': piece_type, 'option': option}

def decode_location_bits(bitstr):
    if len(bitstr) != 8 or any(c not in '01' for c in bitstr):
        return None
    return (int(bitstr[:4], 2), int(bitstr[4:], 2))

# ---------------------------
# Board
# ---------------------------
def make_empty_board():
    return [[{'piece': None, 'option': False, 'checkmate': False}
             for _ in range(8)] for _ in range(8)]

# ---------------------------
# Load images
# ---------------------------
def load_images():
    images = {}
    for key, fname in IMAGE_MAP.items():
        path = os.path.join(IMG_DIR, fname)
        if not os.path.exists(path):
            logging.warning("Missing image: %s", path)
            continue
        img = pygame.image.load(path).convert_alpha()
        images[key] = pygame.transform.smoothscale(img, (SQUARE_PX, SQUARE_PX))
    return images

def load_title_images():
    chess_img = pygame.image.load(TITLE_IMG_CHESS).convert_alpha()
    game_img = pygame.image.load(TITLE_IMG_GAME).convert_alpha()
    chess_img = pygame.transform.smoothscale(chess_img, (int(chess_img.get_width()*0.3),
                                                         int(chess_img.get_height()*0.3)))
    game_img = pygame.transform.smoothscale(game_img, (int(game_img.get_width()*0.3),
                                                       int(game_img.get_height()*0.3)))
    return chess_img, game_img

# ---------------------------
# Serial reader
# ---------------------------
def serial_reader(ser, out_q, stop_event):
    buf = ""
    while not stop_event.is_set():
        try:
            raw = ser.read(64)
            if raw:
                for c in raw.decode('ascii', errors='ignore'):
                    if c in '01':
                        buf += c
                while len(buf) >= 8:
                    out_q.put(buf[:8])
                    buf = buf[8:]
        except:
            time.sleep(0.01)

# ---------------------------
# Main
# ---------------------------
def main():
    pygame.init()
    screen = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
    pygame.display.set_caption("Chess Graphics")
    clock = pygame.time.Clock()

    images = load_images()
    chess_title, game_title = load_title_images()
    board = make_empty_board()

    decoded_moves = {}
    decoded_moves_list = []

    ser = None
    try:
        ser = serial.Serial(SERIAL_PORT, BAUDRATE, timeout=0.05)
    except SerialException as e:
        logging.error("Serial failed: %s", e)

    q = queue.Queue()
    stop = threading.Event()
    if ser:
        threading.Thread(target=serial_reader,
                         args=(ser, q, stop),
                         daemon=True).start()

    pending = None

    panel_center = BEZEL_THICKNESS + BOARD_PX + SIDE_PX // 2
    promo_positions = {}
    bottom_y = WINDOW_HEIGHT - BEZEL_THICKNESS - SQUARE_PX // 2 - SQUARE_PX * 0.75
    for i, loc in enumerate(PROMO_LOCS):
        square_y = bottom_y - i * SQUARE_PX
        square_x = panel_center - SQUARE_PX // 2
        promo_positions[loc] = (square_x, square_y)

    try:
        running = True
        while running:

            for e in pygame.event.get():
                if e.type == pygame.QUIT:
                    running = False
                elif e.type == pygame.MOUSEBUTTONDOWN and e.button == 1:
                    mx, my = e.pos

                    chess_rect = chess_title.get_rect(center=(panel_center, BEZEL_THICKNESS + chess_title.get_height()//2 + 20))
                    game_rect = game_title.get_rect(center=(panel_center, BEZEL_THICKNESS + chess_title.get_height() + 40 + game_title.get_height()//2))

                    if chess_rect.collidepoint(mx, my) or game_rect.collidepoint(mx, my):
                        if ser and ser.is_open:
                            ser.write(bytes([0xFE]))

                    clicked_promo = False
                    for loc, (x, y) in promo_positions.items():
                        rect = pygame.Rect(x, y, SQUARE_PX, SQUARE_PX)
                        if rect.collidepoint(mx, my):
                            if ser and ser.is_open:
                                ser.write(bytes([loc]))
                            clicked_promo = True
                            break

                    if not clicked_promo and (BEZEL_THICKNESS <= mx < BEZEL_THICKNESS + BOARD_PX and
                                              BEZEL_THICKNESS <= my < BEZEL_THICKNESS + BOARD_PX):
                        col = (mx - BEZEL_THICKNESS) // SQUARE_PX
                        row = 7 - ((my - BEZEL_THICKNESS) // SQUARE_PX)
                        val = (row << 4) | col
                        if ser and ser.is_open:
                            ser.write(bytes([val]))

            while not q.empty():
                tok = q.get()
                if pending is None:
                    pending = tok
                else:
                    if pending == '11111111' and tok == '11111111':
                        if ser and ser.is_open:
                            time.sleep(0.25)
                            ser.write(bytes([0xFF]))
                        pending = None
                        continue

                    loc = decode_location_bits(pending)
                    piece = decode_piece_bits(tok)
                    pending = None

                    if loc and piece:
                        r, c = loc

                        promo_loc = (r << 4) | c
                        if promo_loc in PROMO_LOCS:
                            decoded_moves[promo_loc] = piece.copy()
                            decoded_moves_list.append({'loc': promo_loc, 'piece': piece.copy()})
                        else:
                            if 0 <= r < 8 and 0 <= c < 8:
                                cell = board[r][c]

                                cell['piece'] = None
                                cell['checkmate'] = False
                                cell['option'] = piece.get('option', False)

                                if 'checkmate' in piece:
                                    cell['checkmate'] = piece['color']
                                elif piece.get('has_piece'):
                                    cell['piece'] = (piece['color'], piece['type'])

                                decoded_moves[(r, c)] = piece.copy()
                                decoded_moves_list.append({'loc': (r, c), 'piece': piece.copy()})

            screen.fill(COLOR_PANEL)

            for r in range(8):
                for c in range(8):
                    x = BEZEL_THICKNESS + c * SQUARE_PX
                    y = BEZEL_THICKNESS + (7 - r) * SQUARE_PX
                    color = COLOR_GREY if (r + c) % 2 == 0 else COLOR_BLACK
                    pygame.draw.rect(screen, color, (x, y, SQUARE_PX, SQUARE_PX))

                    cell = board[r][c]

                    if cell['checkmate']:
                        pygame.draw.rect(screen, COLOR_CHECKMATE, (x, y, SQUARE_PX, SQUARE_PX))
                        img = images.get((cell['checkmate'], 'k'))
                        if img:
                            screen.blit(img, (x, y))
                        continue

                    if cell['piece']:
                        img = images.get(cell['piece'])
                        if img:
                            screen.blit(img, (x, y))

                    if cell['option']:
                        pygame.draw.circle(screen, COLOR_OPTION,
                                           (x + SQUARE_PX//2, y + SQUARE_PX//2),
                                           SQUARE_PX//8)

            for loc, (x, y) in promo_positions.items():
                pygame.draw.rect(screen, COLOR_PANEL, (x, y, SQUARE_PX, SQUARE_PX))
                piece = decoded_moves.get(loc)
                if piece is not None and (piece.get('has_piece') or piece.get('checkmate')):
                    if 'checkmate' in piece:
                        pygame.draw.rect(screen, COLOR_CHECKMATE, (x, y, SQUARE_PX, SQUARE_PX))
                        img = images.get((piece['color'], 'k'))
                    else:
                        img = images.get((piece['color'], piece['type']))
                    if img:
                        screen.blit(img, (x, y))
                    if piece.get('option'):
                        pygame.draw.circle(screen, COLOR_OPTION,
                                           (x + SQUARE_PX//2, y + SQUARE_PX//2),
                                           SQUARE_PX//8)

            chess_rect = chess_title.get_rect(center=(panel_center, BEZEL_THICKNESS + chess_title.get_height()//2 + 20))
            game_rect = game_title.get_rect(center=(panel_center, BEZEL_THICKNESS + chess_title.get_height() + 40 + game_title.get_height()//2))
            screen.blit(chess_title, chess_rect.topleft)
            screen.blit(game_title, game_rect.topleft)

            pygame.display.flip()
            clock.tick(FPS)

    finally:
        stop.set()
        if ser:
            ser.close()
        pygame.quit()

if __name__ == "__main__":
    main()
