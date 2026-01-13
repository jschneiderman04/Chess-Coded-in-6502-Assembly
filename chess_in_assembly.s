PORTB = $6000 
PORTA = $6001
DDRB  = $6002
DDRA  = $6003 ; ports A and B communicate with the arduino

S     = %00000001
RDY   = %00000010
RDX   = %00000100
L     = %00001000
OPN   = %00100000
BLK   = %00010000

wk    = %10001000
wq    = %10000110
wr    = %10000100
wb    = %10000010
wn    = %10000001
wp    = %10000000

bk    = %11001000
bq    = %11000110
br    = %11000100
bb    = %11000010
bn    = %11000001
bp    = %11000000

WKP   = $80 ; White King Position
BKP   = $81 ; Black King Position

WCA   = $82 ; White Castle Allow
BCA   = $83 ; Black Castle Allow

SQC   = $84 ; SQuare of Contention
SQO   = $85 ; SQuare Original
SQF   = $86 ; SQuare Final

ENS   = $87 ; EN passant Set

UPC   = $88 ; UnPinned Counter (OBS)
CKC   = $89 ; ChecK Counter

SCC   = $8a ; Short Castle Counter (OBS)
LCC   = $8b ; Long Castle Counter (OBS)

OTP   = $8c ; OpTion Pointer
KMP   = $8d ; King Move Pointer (OBS)
BSP   = $8e ; Blocking Square Pointer
BPP   = $8f ; Block Piece Pointer

WENA  = $90 ; set ff ; White EN passant A
WENB  = $91 ; set ff ; White EN passant B
BENA  = $92 ; set ff ; Black EN passant A
BENB  = $93 ; set ff ; Black EN passant B

CSTLR = $94 ; set ff ; CaSTLe Right
CSTLL = $95 ; set ff ; CaSTLe Left
ENP   = $96 ; set ff ; EN Passant
PROM  = $97 ; set ff ; PROMotion

SQR   = $98 ; SQuaRe
PIN   = $99 ; multiuse variable

SSP   = $0a ; Send Sqaure Position
SSV   = $09 ; Send Square Value
SSO   = $08 ; Send Square Other

VLA   = $9c ; VaLue A
VLB   = $9d ; VaLue B
VLC   = $9e ; VaLue C
VLD   = $9f ; VaLue D


  .org $8000

reset:

  ldx #$ff
  txs

  lda #$ff
  sta DDRB
  lda #%00001001
  sta DDRA
  lda #$00
  sta PORTA

main:
  jsr load_white

start:
  jsr load_board

white:

white_start:
  jsr wcheckb
  lda CKC
  bne white_checker

  jmp wnormal ; no checks, act normal

white_checker:
  lda CKC
  cmp #$01
  bne white_checker_for_double

  lda #$e0
  sta OTP
  jsr woption_ki
  lda OTP
  cmp #$e0
  beq white_checker_1 
  jmp wnormal_single

white_checker_1:
  lda #$e0
  sta OTP

  lda #$00
  sta VLB
  jsr w_cfc_enp ; make subroutine
  lda VLB
  beq white_checker_2
  jmp wnormal_single

white_checker_2:
  lda #$00
  sta VLB
  jsr wcfcb
  lda VLB
  bne white_checker_3
  jmp w_hit_fc

white_checker_3:
  jmp wnormal_single

white_checker_for_double:
  lda CKC
  cmp #$02
  bne white_error_cfc_1

  lda #$e0
  sta OTP
  jsr woption_ki
  lda OTP
  cmp #$e0
  bne white_checker_for_double_1
  jmp w_hit_fc
white_checker_for_double_1:
  jmp wnormal_double

white_error_cfc_1:
  lda #$81
  sta $34
  sta $43
  sta $33
  sta $44
  jsr update_board_black
  
;*******

w_hit_fc:
  jsr white_ckmg
  jsr update_board_black
  jmp w_cm_repeat

w_cm_repeat:
  jsr load_black
  lda SQC
  cmp #$89
  bne w_cm_repeat

  jmp start ; reset the game

;******

wnormal:
  jsr update_board_white
wnormal_1:
  jsr load_white
  lda SQC
  cmp #$fe
  bne wnormal_1a
  jmp start
wnormal_1a:
  lda SQC
  and #$88
  bne wnormal_1
  ldx SQC
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq wnormal_2
  jmp wnormal_1
wnormal_2:
  jsr w_piece_option
  lda OTP
  cmp #%11100000
  bne wnormal_3
  jmp wnormal_1
wnormal_3:
  jsr option_to_board
  jsr update_board_white
  lda SQC
  sta SQO
  jsr load_white
  lda SQC
  cmp #$fe
  bne wnormal_3a
  jmp start
wnormal_3a:
  lda SQC
  and #$88
  beq wnormal_3b
  jsr option_clear
  jsr update_board_white
  jmp wnormal_1
wnormal_3b:
  ldx SQC
  lda $00, x
  and #%00100000
  bne wnormal_4
  jsr option_clear
  jsr update_board_white
  jmp wnormal_1a
wnormal_4:
  lda SQC
  sta SQF
  jsr wmove
  jsr delay
  jmp black  


wnormal_double:
  jsr update_board_white
wnormal_double_1:
  jsr load_white
  lda SQC
  cmp #$fe
  bne wnormal_double_1a
  jmp start
wnormal_double_1a:
  lda SQC
  cmp WKP
  beq wnormal_double_2
  jmp wnormal_double_1
wnormal_double_2:
  jsr wreset_tickers
  jsr woption_ki

wnormal_double_3:
  jsr option_to_board
  jsr update_board_white
  lda SQC
  sta SQO
  jsr load_white
  lda SQC
  cmp #$fe
  bne wnormal_double_3a
  jmp start
wnormal_double_3a:
  lda SQC
  and #$88
  beq wnormal_double_3b
  jsr option_clear
  jsr update_board_white
  jmp wnormal_double_1
wnormal_double_3b:
  ldx SQC
  lda $00, x
  and #%00100000
  bne wnormal_double_4
  jsr option_clear
  jsr update_board_white
  jmp wnormal_double_1a
wnormal_double_4:
  lda SQC
  sta SQF
  jsr wmove
  jsr delay
  jmp black 


;*********


wnormal_single:
  jsr update_board_white
wnormal_single_1:
  jsr load_white
  lda SQC
  cmp #$fe
  bne wnormal_single_1a
  jmp start
wnormal_single_1a:
  lda SQC
  and #$88
  bne wnormal_single_1
  ldx SQC
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq wnormal_single_2
  jmp wnormal_single_1
wnormal_single_2:
  jsr w_piece_option_single
  lda OTP
  cmp #%11100000
  bne wnormal_single_3
  jmp wnormal_single_1
wnormal_single_3:
  jsr specialoption
  jsr update_board_white
  lda SQC
  sta SQO
  jsr load_white
  lda SQC
  cmp #$fe
  bne wnormal_single_3a
  jmp start
wnormal_single_3a:
  lda SQC
  and #$88
  beq wnormal_single_3b
  jsr option_clear
  jsr update_board_white
  jmp wnormal_single_1
wnormal_single_3b:
  ldx SQC
  lda $00, x
  and #%00100000
  bne wnormal_single_4
  jsr option_clear
  jsr update_board_white
  jmp wnormal_single_1a
wnormal_single_4:
  lda SQC
  sta SQF
  jsr wmove
  jsr delay
  jmp black  

;**********************************************************
;**********************************************************
;**********************************************************

black:

black_start:
  jsr bcheckb
  lda CKC
  bne black_checker

  jmp bnormal

black_checker:
  lda CKC
  cmp #$01
  bne black_checker_for_double

  lda #$e0
  sta OTP
  jsr boption_ki
  lda OTP
  cmp #$e0
  beq black_checker_1
  jmp bnormal_single

black_checker_1:
  lda #$0e
  sta OTP

  lda #$00
  sta VLB
  jsr b_cfc_enp
  lda VLB
  beq black_checker_2
  jmp bnormal_single

black_checker_2:
  lda #$00
  sta VLB
  jsr bcfcb
  lda VLB
  bne black_checker_3
  jmp b_hit_fc

black_checker_3:
  jmp bnormal_single



black_checker_for_double:
  lda CKC
  cmp #$02
  bne black_error_cfc_1

  lda #$e0
  sta OTP
  jsr boption_ki
  lda OTP
  cmp #$0e
  bne black_checker_for_double_1
  jmp b_hit_fc
black_checker_for_double_1:
  jmp bnormal_double

black_error_cfc_1:
  lda #$c1
  sta $34
  sta $44
  sta $33
  sta $43
  jsr update_board_white


;*****

b_hit_fc:
  jsr black_ckmg
  jsr update_board_white
  jmp b_cm_repeat

b_cm_repeat:
  jsr load_white
  lda SQC
  cmp #$fe
  bne b_cm_repeat

  jmp start


bnormal:
  jsr update_board_black
bnormal_1:
  jsr load_black
  lda SQC
  cmp #$89
  bne bnormal_1a
  jmp start
bnormal_1a:
  lda SQC
  and #$88
  bne bnormal_1
  ldx SQC
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq bnormal_2
  jmp bnormal_1
bnormal_2:
  jsr b_piece_option
  lda OTP
  cmp #%11100000
  bne bnormal_3
  jmp bnormal_1
bnormal_3:
  jsr option_to_board
  jsr update_board_black
  lda SQC
  sta SQO
  jsr load_black
  lda SQC
  cmp #$89
  bne bnormal_3a
  jmp start
bnormal_3a:
  lda SQC
  and #$88
  beq bnormal_3b
  jsr option_clear
  jsr update_board_black
  jmp bnormal_1
bnormal_3b:
  ldx SQC
  lda $00, x
  and #%00100000
  bne bnormal_4
  jsr option_clear
  jsr update_board_black
  jmp bnormal_1a
bnormal_4:
  lda SQC
  sta SQF
  jsr bmove
  jsr delay
  jmp white  


bnormal_double:
  jsr update_board_black
bnormal_double_1:
  jsr load_black
  lda SQC
  cmp #$fe
  bne bnormal_double_1a
  jmp start
bnormal_double_1a:
  lda SQC
  cmp BKP
  beq bnormal_double_2
  jmp bnormal_double_1
bnormal_double_2:
  jsr breset_tickers
  jsr boption_ki

bnormal_double_3:
  jsr option_to_board
  jsr update_board_black
  lda SQC
  sta SQO
  jsr load_black
  lda SQC
  cmp #$89
  bne bnormal_double_3a
  jmp start
bnormal_double_3a:
  lda SQC
  and #$88
  beq bnormal_double_3b
  jsr option_clear
  jsr update_board_black
  jmp bnormal_double_1
bnormal_double_3b:
  ldx SQC
  lda $00, x
  and #%00100000
  bne bnormal_double_4
  jsr option_clear
  jsr update_board_black
  jmp bnormal_double_1a
bnormal_double_4:
  lda SQC
  sta SQF
  jsr bmove
  jsr delay
  jmp white


;*********


bnormal_single:
  jsr update_board_black
bnormal_single_1:
  jsr load_black
  lda SQC
  cmp #$89
  bne bnormal_single_1a
  jmp start
bnormal_single_1a:
  lda SQC
  and #$88
  bne bnormal_single_1
  ldx SQC
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq bnormal_single_2
  jmp bnormal_single_1
bnormal_single_2:
  jsr b_piece_option_single
  lda OTP
  cmp #%11100000
  bne bnormal_single_3
  jmp bnormal_single_1
bnormal_single_3:
  jsr specialoption
  jsr update_board_black
  lda SQC
  sta SQO
  jsr load_black
  lda SQC
  cmp #$89
  bne bnormal_single_3a
  jmp start
bnormal_single_3a:
  lda SQC
  and #$88
  beq bnormal_single_3b
  jsr option_clear
  jsr update_board_black
  jmp bnormal_single_1
bnormal_single_3b:
  ldx SQC
  lda $00, x
  and #%00100000
  bne bnormal_single_4
  jsr option_clear
  jsr update_board_black
  jmp bnormal_single_1a
bnormal_single_4:
  lda SQC
  sta SQF
  jsr bmove
  jsr delay
  jmp white  

;**********************************************************
;**********************************************************
;**********************************************************

;SUBROUTINES


;CHECK FOR CHECK MAIN START FUNCTION SUBROUTINES FIRST

;**********************************************************
;**********************************************************
;**********************************************************

w_cfc_enp:
  lda BENA
  cmp #$ff
  bne w_cfc_enp_1
  jmp w_cfc_enp_end

w_cfc_enp_1:
  lda BENA
  clc
  adc #$01
  tax
  and #$88
  bne w_cfc_enp_2

  lda $00, x
  and #%11001111
  cmp #wp
  bne w_cfc_enp_2

  stx SQR
  jsr wcif
  lda PIN
  bne w_cfc_enp_2

  jmp w_cfc_enp_hit

w_cfc_enp_2:
  lda BENA
  sec
  sbc #$01
  bcc w_cfc_enp_end
  tax
  and #$88
  bne w_cfc_enp_end

  lda $00, x
  and #%11001111
  cmp #wp
  bne w_cfc_enp_end

  stx SQR
  jsr wcif
  lda PIN
  bne w_cfc_enp_end

  jmp w_cfc_enp_hit


w_cfc_enp_hit:
  lda #$ff
  sta VLB

w_cfc_enp_end:
  rts


;**********************************************************


b_cfc_enp:
  lda WENA
  cmp #$ff
  bne b_cfc_enp_1
  jmp b_cfc_enp_end

b_cfc_enp_1:
  lda WENA
  clc
  adc #$01
  tax
  and #$88
  bne b_cfc_enp_2

  lda $00, x
  and #%11001111
  cmp #bp
  bne b_cfc_enp_2

  stx SQR
  jsr bcif
  lda PIN
  bne b_cfc_enp_2

  jmp b_cfc_enp_hit

b_cfc_enp_2:
  lda WENA
  sec
  sbc #$01
  bcc b_cfc_enp_end
  tax
  and #$88
  bne b_cfc_enp_end

  lda $00, x
  and #%11001111
  cmp #bp
  bne b_cfc_enp_end

  stx SQR
  jsr bcif
  lda PIN
  bne b_cfc_enp_end

  jmp b_cfc_enp_hit


b_cfc_enp_hit:
  lda #$ff
  sta VLB

b_cfc_enp_end:
  rts

;**********************************************************

wcfcb:
wcfcb_1:
  ldy BSP
  lda $00, y
  sta SQR
  jsr w_capable

wcfcb_2:
  dey
  tya
  cmp #$d0
  beq wcfcb_3

  lda $00, y
  sta SQR
  jsr w_blockable
  jmp wcfcb_2

wcfcb_3:
  ldy BPP

wcfcb_4:
  tya
  cmp #$b0
  beq wcfcb_ckm

  lda $00, y
  sta SQR
  jsr wcif
  lda PIN
  beq wcfcb_safe

  dey
  jmp wcfcb_4

wcfcb_safe:
  lda #$ff
  sta VLB
  jmp wcfcb_end

wcfcb_ckm:
  lda #$00
  sta VLB

wcfcb_end:
  rts



;**********************************************************

bcfcb:
bcfcb_1:
  ldy BSP
  lda $00, y
  sta SQR
  jsr b_capable

bcfcb_2:
  dey
  tya
  cmp #$d0
  beq bcfcb_3

  lda $00, y
  sta SQR
  jsr b_blockable
  jmp bcfcb_2

bcfcb_3:
  ldy BPP

bcfcb_4:
  tya
  cmp #$b0
  beq bcfcb_ckm

  lda $00, y
  sta SQR
  jsr bcif
  lda PIN
  beq bcfcb_safe

  dey
  jmp bcfcb_4

bcfcb_safe:
  lda #$ff
  sta VLB
  jmp bcfcb_end

bcfcb_ckm:
  lda #$00
  sta VLB

bcfcb_end:
  rts  

;**********************************************************

w_piece_option_single:
  lda SQC
  sta SQR
  jsr wcif

  lda PIN
  bne w_piece_option1_single
  jsr w_piece_pop0_single
  jmp w_piece_optione_single

w_piece_option1_single:
  lda PIN
  cmp #%10000000
  bne w_piece_option2_single
  jsr w_piece_pop1
  jmp w_piece_optione_single

w_piece_option2_single:
  lda PIN
  cmp #%01000000
  bne w_piece_option3_single
  jsr w_piece_pop2
  jmp w_piece_optione_single

w_piece_option3_single:
  lda PIN
  cmp #%00100000
  bne w_piece_option4_single
  jsr w_piece_pop3
  jmp w_piece_optione_single

w_piece_option4_single:
  lda PIN
  cmp #%00010000
  bne w_piece_optione_single
  jsr w_piece_pop4
  jmp w_piece_optione_single
	
w_piece_optione_single:
  rts

;**********************************************************


b_piece_option_single:
  lda SQC
  sta SQR
  jsr bcif

  lda PIN
  bne b_piece_option1_single
  jsr b_piece_pop0_single
  jmp b_piece_optione_single

b_piece_option1_single:
  lda PIN
  cmp #%10000000
  bne b_piece_option2_single
  jsr b_piece_pop1
  jmp b_piece_optione_single

b_piece_option2_single:
  lda PIN
  cmp #%01000000
  bne b_piece_option3_single
  jsr b_piece_pop2
  jmp b_piece_optione_single

b_piece_option3_single:
  lda PIN
  cmp #%00100000
  bne b_piece_option4_single
  jsr b_piece_pop3
  jmp b_piece_optione_single

b_piece_option4_single:
  lda PIN
  cmp #%00010000
  bne b_piece_optione_single
  jsr b_piece_pop4
  jmp b_piece_optione_single
	
b_piece_optione_single:
  rts

;**********************************************************

w_piece_pop0_single:
  jsr wreset_tickers
wq_ask0_single:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wq
  bne wr_ask0_single
  jmp woption_queen0_single
wr_ask0_single:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wr
  bne wb_ask0_single
  jmp woption_rook0_single
wb_ask0_single:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wb
  bne wn_ask0_single
  jmp woption_bishop0_single
wn_ask0_single:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wn
  bne wp_ask0_single
  jmp woption_knight0_single
wp_ask0_single:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wp
  bne wk_ask0_single
  jmp woption_pawn0_single
wk_ask0_single:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wk
  bne w_piece_option_ed0_single
  jmp woption_king0_single
w_piece_option_ed0_single:
  jmp w_piece_option_e0_single

woption_queen0_single:
  jsr woption_n
  jsr woption_e
  jsr woption_s
  jsr woption_w
  jsr woption_ne
  jsr woption_se
  jsr woption_sw
  jsr woption_nw
  jmp w_piece_option_e0_single

woption_rook0_single:
  jsr woption_n
  jsr woption_e
  jsr woption_s
  jsr woption_w
  jmp w_piece_option_e0_single

woption_bishop0_single:
  jsr woption_ne
  jsr woption_se
  jsr woption_sw
  jsr woption_nw
  jmp w_piece_option_e0_single

woption_knight0_single:
  jsr woption_kn
  jmp w_piece_option_e0_single

woption_pawn0_single:
  jsr woption_pn_fw
  jsr woption_pn_cap_nw
  jsr woption_pn_cap_ne
  jsr woption_pn_en
  jmp w_piece_option_e0_single

woption_king0_single:
  jsr woption_ki
  jmp w_piece_option_e0

w_piece_option_e0_single:
  rts


;************************************************

b_piece_pop0_single:
  jsr breset_tickers
bq_ask0_single:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bq
  bne br_ask0_single
  jmp boption_queen0_single
br_ask0_single:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #br
  bne bb_ask0_single
  jmp boption_rook0_single
bb_ask0_single:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bb
  bne bn_ask0_single
  jmp boption_bishop0_single
bn_ask0_single:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bn
  bne bp_ask0_single
  jmp boption_knight0_single
bp_ask0_single:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bp
  bne bk_ask0_single
  jmp boption_pawn0_single
bk_ask0_single:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bk
  bne b_piece_option_ed0_single
  jmp boption_king0_single
b_piece_option_ed0_single:
  jmp b_piece_option_e0_single

boption_queen0_single:
  jsr boption_n
  jsr boption_e
  jsr boption_s
  jsr boption_w
  jsr boption_ne
  jsr boption_se
  jsr boption_sw
  jsr boption_nw
  jmp b_piece_option_e0_single

boption_rook0_single:
  jsr boption_n
  jsr boption_e
  jsr boption_s
  jsr boption_w
  jmp b_piece_option_e0_single

boption_bishop0_single:
  jsr boption_ne
  jsr boption_se
  jsr boption_sw
  jsr boption_nw
  jmp b_piece_option_e0_single

boption_knight0_single:
  jsr boption_kn
  jmp b_piece_option_e0_single

boption_pawn0_single:
  jsr boption_pn_fw
  jsr boption_pn_cap_sw
  jsr boption_pn_cap_se
  jsr boption_pn_en
  jmp b_piece_option_e0_single

boption_king0_single:
  jsr boption_ki
  jmp b_piece_option_e0_single

b_piece_option_e0_single:
  rts

;**********************************************************

wcheckb:
  ldy #$d0

  lda #$00
  sta CKC
  lda #$d0
  sta BSP

  jsr wcheckb_kn
  jsr wcheckb_pn
  jsr wcheckb_bi
  jsr wcheckb_ro

  sty BSP

  rts

;**********************************************************

wcheckb_kn:
  lda WKP
  clc
  adc #$21
  tax
  and #$88
  bne wcheckb_kn_1
  lda $00, x
  and #%11001111
  cmp #bn
  bne wcheckb_kn_1
  ldy BSP
  iny
  stx $00, y
  ldx CKC
  inx
  stx CKC
  sty BSP
  jmp wcheckb_kn_e
wcheckb_kn_1:
  lda WKP
  clc
  adc #$1f
  tax
  and #$88
  bne wcheckb_kn_2
  lda $00, x
  and #%11001111
  cmp #bn
  bne wcheckb_kn_2
  ldy BSP
  iny
  stx $00, y
  ldx CKC
  inx
  stx CKC
  sty BSP
  jmp wcheckb_kn_e
wcheckb_kn_2:
  lda WKP
  clc
  adc #$12
  tax
  and #$88
  bne wcheckb_kn_3
  lda $00, x
  and #%11001111
  cmp #bn
  bne wcheckb_kn_3
  ldy BSP
  iny
  stx $00, y
  ldx CKC
  inx
  stx CKC
  sty BSP
  jmp wcheckb_kn_e
wcheckb_kn_3:
  lda WKP
  clc
  adc #$0e
  tax
  and #$88
  bne wcheckb_kn_4
  lda $00, x
  and #%11001111
  cmp #bn
  bne wcheckb_kn_4
  ldy BSP
  iny
  stx $00, y
  ldx CKC
  inx
  stx CKC
  sty BSP
  jmp wcheckb_kn_e
wcheckb_kn_4:
  lda WKP
  sec
  sbc #$21
  bcc wcheckb_kn_5
  tax
  and #$88
  bne wcheckb_kn_5
  lda $00, x
  and #%11001111
  cmp #bn
  bne wcheckb_kn_5
  ldy BSP
  iny
  stx $00, y
  ldx CKC
  inx
  stx CKC
  sty BSP
  jmp wcheckb_kn_e
wcheckb_kn_5:
  lda WKP
  sec
  sbc #$12
  bcc wcheckb_kn_6
  tax
  and #$88
  bne wcheckb_kn_6
  lda $00, x
  and #%11001111
  cmp #bn
  bne wcheckb_kn_6
  ldy BSP
  iny
  stx $00, y
  ldx CKC
  inx
  stx CKC
  sty BSP
  jmp wcheckb_kn_e
wcheckb_kn_6:
  lda WKP
  sec
  sbc #$0e
  bcc wcheckb_kn_7
  tax
  and #$88
  bne wcheckb_kn_7
  lda $00, x
  and #%11001111
  cmp #bn
  bne wcheckb_kn_7
  ldy BSP
  iny
  stx $00, y
  ldx CKC
  inx
  stx CKC
  sty BSP
  jmp wcheckb_kn_e
wcheckb_kn_7:
  lda WKP
  sec
  sbc #$1f
  bcc wcheckb_kn_e
  tax
  and #$88
  bne wcheckb_kn_e
  lda $00, x
  and #%11001111
  cmp #bn
  bne wcheckb_kn_e
  ldy BSP
  iny
  stx $00, y
  ldx CKC
  inx
  stx CKC
  sty BSP
wcheckb_kn_e:
  rts
;**********************************************************


wcheckb_pn:
  lda WKP
  clc
  adc #$11
  tax
  and #$88
  bne wcheckb_pn_1
  lda $00, x
  and #%11001111
  cmp #bp
  bne wcheckb_pn_1
  ldy BSP
  iny
  stx $00, y
  ldx CKC
  inx
  stx CKC
  sty BSP
  jmp wcheckb_pn_e
wcheckb_pn_1:
  lda WKP
  clc
  adc #$0f
  tax
  and #$88
  bne wcheckb_pn_e
  lda $00, x
  and #%11001111
  cmp #bp
  bne wcheckb_pn_e
  ldy BSP
  iny
  stx $00, y
  ldx CKC
  inx
  stx CKC
  sty BSP
wcheckb_pn_e:
  rts

;**********************************************************

wcheckb_bi:

wcheckb_bi_ne:
  lda WKP
wcheckb_bi_ne_1:
  clc
  adc #$11
  tax
  and #$88
  bne wcheckb_bi_nv
  lda $00, x
  and #$80
  bne wcheckb_bi_ne_2
  txa
  jmp wcheckb_bi_ne_1
wcheckb_bi_ne_2:
  lda $00, x
  and #%11001111
  sta VLC
  cmp #bb
  beq wcheckb_bi_ne_3
  lda VLC
  cmp #bq
  beq wcheckb_bi_ne_3
  jmp wcheckb_bi_nv
wcheckb_bi_ne_3:
  stx VLD
  ldx CKC
  inx
  stx CKC

  lda WKP
  clc
  adc #$11
  tax
wcheckb_bi_ne_4:
  iny
  stx $00, y
  cmp VLD
  beq wcheckb_bi_ne_5
  txa
  clc
  adc #$11
  tax
  jmp wcheckb_bi_ne_4
wcheckb_bi_ne_5:
  jmp wcheckb_bi_end


;**********************************************************


wcheckb_bi_nv:
  lda WKP
wcheckb_bi_nv_1:
  clc
  adc #$0f
  tax
  and #$88
  bne wcheckb_bi_se
  lda $00, x
  and #$80
  bne wcheckb_bi_nv_2
  txa
  jmp wcheckb_bi_nv_1
wcheckb_bi_nv_2:
  lda $00, x
  and #%11001111
  sta VLC
  cmp #bb
  beq wcheckb_bi_nv_3
  lda VLC
  cmp #bq
  beq wcheckb_bi_nv_3
  jmp wcheckb_bi_se
wcheckb_bi_nv_3:
  stx VLD
  ldx CKC
  inx
  stx CKC

  lda WKP
  clc
  adc #$0f
  tax
wcheckb_bi_nv_4:
  iny
  stx $00, y
  cmp VLD
  beq wcheckb_bi_nv_5
  txa
  clc
  adc #$0f
  tax
  jmp wcheckb_bi_nv_4
wcheckb_bi_nv_5:
  jmp wcheckb_bi_end


;**********************************************************


wcheckb_bi_se:
  lda WKP
wcheckb_bi_se_1:
  sec
  sbc #$0f
  bcs wcheckb_bi_se_1b
  jmp wcheckb_bi_sv
wcheckb_bi_se_1b:
  tax
  and #$88
  bne wcheckb_bi_sv
  lda $00, x
  and #$80
  bne wcheckb_bi_se_2
  txa
  jmp wcheckb_bi_se_1
wcheckb_bi_se_2:
  lda $00, x
  and #%11001111
  sta VLC
  cmp #bb
  beq wcheckb_bi_se_3
  lda VLC
  cmp #bq
  beq wcheckb_bi_se_3
  jmp wcheckb_bi_sv
wcheckb_bi_se_3:
  stx VLD
  ldx CKC
  inx
  stx CKC

  lda WKP
  sec
  sbc #$0f
  tax
wcheckb_bi_se_4:
  iny
  stx $00, y
  cmp VLD
  beq wcheckb_bi_se_5
  txa
  sec
  sbc #$0f
  tax
  jmp wcheckb_bi_se_4
wcheckb_bi_se_5:
  jmp wcheckb_bi_end


;**********************************************************


wcheckb_bi_sv:
  lda WKP
wcheckb_bi_sv_1:
  sec
  sbc #$11
  bcs wcheckb_bi_sv_1b
  jmp wcheckb_bi_end
wcheckb_bi_sv_1b:
  tax
  and #$88
  bne wcheckb_bi_end
  lda $00, x
  and #$80
  bne wcheckb_bi_sv_2
  txa
  jmp wcheckb_bi_sv_1
wcheckb_bi_sv_2:
  lda $00, x
  and #%11001111
  sta VLC
  cmp #bb
  beq wcheckb_bi_sv_3
  lda VLC
  cmp #bq
  beq wcheckb_bi_sv_3
  jmp wcheckb_bi_end
wcheckb_bi_sv_3:
  stx VLD
  ldx CKC
  inx
  stx CKC

  lda WKP
  sec
  sbc #$11
  tax
wcheckb_bi_sv_4:
  iny
  stx $00, y
  cmp VLD
  beq wcheckb_bi_sv_5
  txa
  sec
  sbc #$11
  tax
  jmp wcheckb_bi_sv_4
wcheckb_bi_sv_5:
  jmp wcheckb_bi_end

wcheckb_bi_end:
  rts

;**********************************************************


wcheckb_ro:

wcheckb_ro_n:
  lda WKP
wcheckb_ro_n_1:
  clc
  adc #$10
  tax
  and #$88
  bne wcheckb_ro_e
  lda $00, x
  and #$80
  bne wcheckb_ro_n_2
  txa
  jmp wcheckb_ro_n_1
wcheckb_ro_n_2:
  lda $00, x
  and #%11001111
  sta VLC
  cmp #br
  beq wcheckb_ro_n_3
  lda VLC
  cmp #bq
  beq wcheckb_ro_n_3
  jmp wcheckb_ro_e
wcheckb_ro_n_3:
  stx VLD
  ldx CKC
  inx
  stx CKC

  lda WKP
  clc
  adc #$10
  tax
wcheckb_ro_n_4:
  iny
  stx $00, y
  cmp VLD
  beq wcheckb_ro_n_5
  txa
  clc
  adc #$10
  tax
  jmp wcheckb_ro_n_4
wcheckb_ro_n_5:
  jmp wcheckb_ro_end


;**********************************************************


wcheckb_ro_e:
  lda WKP
wcheckb_ro_e_1:
  clc
  adc #$01
  tax
  and #$88
  bne wcheckb_ro_s
  lda $00, x
  and #$80
  bne wcheckb_ro_e_2
  txa
  jmp wcheckb_ro_e_1
wcheckb_ro_e_2:
  lda $00, x
  and #%11001111
  sta VLC
  cmp #br
  beq wcheckb_ro_e_3
  lda VLC
  cmp #bq
  beq wcheckb_ro_e_3
  jmp wcheckb_ro_s
wcheckb_ro_e_3:
  stx VLD
  ldx CKC
  inx
  stx CKC

  lda WKP
  clc
  adc #$01
  tax
wcheckb_ro_e_4:
  iny
  stx $00, y
  cmp VLD
  beq wcheckb_ro_e_5
  txa
  clc
  adc #$01
  tax
  jmp wcheckb_ro_e_4
wcheckb_ro_e_5:
  jmp wcheckb_ro_end

;**********************************************************

wcheckb_ro_s:
  lda WKP
wcheckb_ro_s_1:
  sec
  sbc #$10
  bcs wcheckb_ro_s_1b
  jmp wcheckb_ro_v
wcheckb_ro_s_1b:
  tax
  and #$88
  bne wcheckb_ro_v
  lda $00, x
  and #$80
  bne wcheckb_ro_s_2
  txa
  jmp wcheckb_ro_s_1
wcheckb_ro_s_2:
  lda $00, x
  and #%11001111
  sta VLC
  cmp #br
  beq wcheckb_ro_s_3
  lda VLC
  cmp #bq
  beq wcheckb_ro_s_3
  jmp wcheckb_ro_v
wcheckb_ro_s_3:
  stx VLD
  ldx CKC
  inx
  stx CKC

  lda WKP
  sec
  sbc #$10
  tax
wcheckb_ro_s_4:
  iny
  stx $00, y
  cmp VLD
  beq wcheckb_ro_s_5
  txa
  sec
  sbc #$10
  tax
  jmp wcheckb_ro_s_4
wcheckb_ro_s_5:
  jmp wcheckb_ro_end


;**********************************************************


wcheckb_ro_v:
  lda WKP
wcheckb_ro_v_1:
  sec
  sbc #$01
  bcs wcheckb_ro_v_1b
  jmp wcheckb_ro_end
wcheckb_ro_v_1b:
  tax
  and #$88
  bne wcheckb_ro_end
  lda $00, x
  and #$80
  bne wcheckb_ro_v_2
  txa
  jmp wcheckb_ro_v_1
wcheckb_ro_v_2:
  lda $00, x
  and #%11001111
  sta VLC
  cmp #br
  beq wcheckb_ro_v_3
  lda VLC
  cmp #bq
  beq wcheckb_ro_v_3
  jmp wcheckb_ro_end
wcheckb_ro_v_3:
  stx VLD
  ldx CKC
  inx
  stx CKC

  lda WKP
  sec
  sbc #$01
  tax
wcheckb_ro_v_4:
  iny
  stx $00, y
  cmp VLD
  beq wcheckb_ro_v_5
  txa
  sec
  sbc #$01
  tax
  jmp wcheckb_ro_v_4
wcheckb_ro_v_5:
  jmp wcheckb_ro_end

;**********************************************************

wcheckb_ro_end:
  rts

;**********************************************************

bcheckb:
  ldy #$d0

  lda #$00
  sta CKC
  lda #$d0
  sta BSP

  jsr bcheckb_kn
  jsr bcheckb_pn
  jsr bcheckb_bi
  jsr bcheckb_ro

  sty BSP

  rts

;**********************************************************


bcheckb_kn:
  ldy BSP
  lda BKP
  clc
  adc #$21
  tax
  and #$88
  bne bcheckb_kn_1
  lda $00, x
  and #%11001111
  cmp #wn
  bne bcheckb_kn_1
  iny
  stx $00, y
  ldx CKC
  inx
  stx CKC
  sty BSP
  jmp bcheckb_kn_e
bcheckb_kn_1:
  lda BKP
  clc
  adc #$1f
  tax
  and #$88
  bne bcheckb_kn_2
  lda $00, x
  and #%11001111
  cmp #wn
  bne bcheckb_kn_2
  iny
  stx $00, y
  ldx CKC
  inx
  stx CKC
  sty BSP
  jmp bcheckb_kn_e
bcheckb_kn_2:
  lda BKP
  clc
  adc #$12
  tax
  and #$88
  bne bcheckb_kn_3
  lda $00, x
  and #%11001111
  cmp #wn
  bne bcheckb_kn_3
  iny
  stx $00, y
  ldx CKC
  inx
  stx CKC
  sty BSP
  jmp bcheckb_kn_e
bcheckb_kn_3:
  lda BKP
  clc
  adc #$0e
  tax
  and #$88
  bne bcheckb_kn_4
  lda $00, x
  and #%11001111
  cmp #wn
  bne bcheckb_kn_4
  iny
  stx $00, y
  ldx CKC
  inx
  stx CKC
  sty BSP
  jmp bcheckb_kn_e
bcheckb_kn_4:
  lda BKP
  sec
  sbc #$21
  bcc bcheckb_kn_5
  tax
  and #$88
  bne bcheckb_kn_5
  lda $00, x
  and #%11001111
  cmp #wn
  bne bcheckb_kn_5
  iny
  stx $00, y
  ldx CKC
  inx
  stx CKC
  sty BSP
  jmp bcheckb_kn_e
bcheckb_kn_5:
  lda BKP
  sec
  sbc #$12
  bcc bcheckb_kn_6
  tax
  and #$88
  bne bcheckb_kn_6
  lda $00, x
  and #%11001111
  cmp #wn
  bne bcheckb_kn_6
  iny
  stx $00, y
  ldx CKC
  inx
  stx CKC
  sty BSP
  jmp bcheckb_kn_e
bcheckb_kn_6:
  lda BKP
  sec
  sbc #$0e
  bcc bcheckb_kn_7
  tax
  and #$88
  bne bcheckb_kn_7
  lda $00, x
  and #%11001111
  cmp #wn
  bne bcheckb_kn_7
  iny
  stx $00, y
  ldx CKC
  inx
  stx CKC
  sty BSP
  jmp bcheckb_kn_e
bcheckb_kn_7:
  lda BKP
  sec
  sbc #$1f
  bcc bcheckb_kn_e
  tax
  and #$88
  bne bcheckb_kn_e
  lda $00, x
  and #%11001111
  cmp #wn
  bne bcheckb_kn_e
  iny
  stx $00, y
  ldx CKC
  inx
  stx CKC
bcheckb_kn_e:
  sty BSP
  rts


;**********************************************************


bcheckb_pn:
  ldy BSP
  lda BKP
  sec
  sbc #$11
  tax
  and #$88
  bne bcheckb_pn_1
  lda $00, x
  and #%11001111
  cmp #wp
  bne bcheckb_pn_1
  iny
  stx $00, y
  ldx CKC
  inx
  stx CKC
  jmp bcheckb_pn_e
bcheckb_pn_1:
  lda BKP
  sec
  sbc #$0f
  tax
  and #$88
  bne bcheckb_pn_e
  lda $00, x
  and #%11001111
  cmp #wp
  bne bcheckb_pn_e
  iny
  stx $00, y
  ldx CKC
  inx
  stx CKC
bcheckb_pn_e:
  sty BSP
  rts

;**********************************************************

bcheckb_bi:

bcheckb_bi_ne:
  lda BKP
bcheckb_bi_ne_1:
  clc
  adc #$11
  tax
  and #$88
  bne bcheckb_bi_nv
  lda $00, x
  and #$80
  bne bcheckb_bi_ne_2
  txa
  jmp bcheckb_bi_ne_1
bcheckb_bi_ne_2:
  lda $00, x
  and #%11001111
  sta VLC
  cmp #wb
  beq bcheckb_bi_ne_3
  lda VLC
  cmp #wq
  beq bcheckb_bi_ne_3
  jmp bcheckb_bi_nv
bcheckb_bi_ne_3:
  stx VLD
  ldx CKC
  inx
  stx CKC

  lda BKP
  clc
  adc #$11
  tax
bcheckb_bi_ne_4:
  iny
  stx $00, y
  cmp VLD
  beq bcheckb_bi_ne_5
  txa
  clc
  adc #$11
  tax
  jmp bcheckb_bi_ne_4
bcheckb_bi_ne_5:
  jmp bcheckb_bi_end


;**********************************************************


bcheckb_bi_nv:
  lda BKP
bcheckb_bi_nv_1:
  clc
  adc #$0f
  tax
  and #$88
  bne bcheckb_bi_se
  lda $00, x
  and #$80
  bne bcheckb_bi_nv_2
  txa
  jmp bcheckb_bi_nv_1
bcheckb_bi_nv_2:
  lda $00, x
  and #%11001111
  sta VLC
  cmp #wb
  beq bcheckb_bi_nv_3
  lda VLC
  cmp #wq
  beq bcheckb_bi_nv_3
  jmp bcheckb_bi_se
bcheckb_bi_nv_3:
  stx VLD
  ldx CKC
  inx
  stx CKC

  lda BKP
  clc
  adc #$0f
  tax
bcheckb_bi_nv_4:
  iny
  stx $00, y
  cmp VLD
  beq bcheckb_bi_nv_5
  txa
  clc
  adc #$0f
  tax
  jmp bcheckb_bi_nv_4
bcheckb_bi_nv_5:
  jmp bcheckb_bi_end


;**********************************************************


bcheckb_bi_se:
  lda BKP
bcheckb_bi_se_1:
  sec
  sbc #$0f
  bcs bcheckb_bi_se_1b
  jmp bcheckb_bi_sv
bcheckb_bi_se_1b:
  tax
  and #$88
  bne bcheckb_bi_sv
  lda $00, x
  and #$80
  bne bcheckb_bi_se_2
  txa
  jmp bcheckb_bi_se_1
bcheckb_bi_se_2:
  lda $00, x
  and #%11001111
  sta VLC
  cmp #wb
  beq bcheckb_bi_se_3
  lda VLC
  cmp #wq
  beq bcheckb_bi_se_3
  jmp bcheckb_bi_sv
bcheckb_bi_se_3:
  stx VLD
  ldx CKC
  inx
  stx CKC

  lda BKP
  sec
  sbc #$0f
  tax
bcheckb_bi_se_4:
  iny
  stx $00, y
  cmp VLD
  beq bcheckb_bi_se_5
  txa
  sec
  sbc #$0f
  tax
  jmp bcheckb_bi_se_4
bcheckb_bi_se_5:
  jmp bcheckb_bi_end


;**********************************************************


bcheckb_bi_sv:
  lda BKP
bcheckb_bi_sv_1:
  sec
  sbc #$11
  bcs bcheckb_bi_sv_1b
  jmp bcheckb_bi_end
bcheckb_bi_sv_1b:
  tax
  and #$88
  bne bcheckb_bi_end
  lda $00, x
  and #$80
  bne bcheckb_bi_sv_2
  txa
  jmp bcheckb_bi_sv_1
bcheckb_bi_sv_2:
  lda $00, x
  and #%11001111
  sta VLC
  cmp #wb
  beq bcheckb_bi_sv_3
  lda VLC
  cmp #wq
  beq bcheckb_bi_sv_3
  jmp bcheckb_bi_end
bcheckb_bi_sv_3:
  stx VLD
  ldx CKC
  inx
  stx CKC

  lda BKP
  sec
  sbc #$11
  tax
bcheckb_bi_sv_4:
  iny
  stx $00, y
  cmp VLD
  beq bcheckb_bi_sv_5
  txa
  sec
  sbc #$11
  tax
  jmp bcheckb_bi_sv_4
bcheckb_bi_sv_5:
  jmp bcheckb_bi_end

bcheckb_bi_end:
  rts

;**********************************************************


bcheckb_ro:

bcheckb_ro_n:
  lda BKP
bcheckb_ro_n_1:
  clc
  adc #$10
  tax
  and #$88
  bne bcheckb_ro_e
  lda $00, x
  and #$80
  bne bcheckb_ro_n_2
  txa
  jmp bcheckb_ro_n_1
bcheckb_ro_n_2:
  lda $00, x
  and #%11001111
  sta VLC
  cmp #wr
  beq bcheckb_ro_n_3
  lda VLC
  cmp #wq
  beq bcheckb_ro_n_3
  jmp bcheckb_ro_e
bcheckb_ro_n_3:
  stx VLD
  ldx CKC
  inx
  stx CKC

  lda BKP
  clc
  adc #$10
  tax
bcheckb_ro_n_4:
  iny
  stx $00, y
  cmp VLD
  beq bcheckb_ro_n_5
  txa
  clc
  adc #$10
  tax
  jmp bcheckb_ro_n_4
bcheckb_ro_n_5:
  jmp bcheckb_ro_end


;**********************************************************


bcheckb_ro_e:
  lda BKP
bcheckb_ro_e_1:
  clc
  adc #$01
  tax
  and #$88
  bne bcheckb_ro_s
  lda $00, x
  and #$80
  bne bcheckb_ro_e_2
  txa
  jmp bcheckb_ro_e_1
bcheckb_ro_e_2:
  lda $00, x
  and #%11001111
  sta VLC
  cmp #wr
  beq bcheckb_ro_e_3
  lda VLC
  cmp #wq
  beq bcheckb_ro_e_3
  jmp bcheckb_ro_s
bcheckb_ro_e_3:
  stx VLD
  ldx CKC
  inx
  stx CKC

  lda BKP
  clc
  adc #$01
  tax
bcheckb_ro_e_4:
  iny
  stx $00, y
  cmp VLD
  beq bcheckb_ro_e_5
  txa
  clc
  adc #$01
  tax
  jmp bcheckb_ro_e_4
bcheckb_ro_e_5:
  jmp bcheckb_ro_end


;**********************************************************


bcheckb_ro_s:
  lda BKP
bcheckb_ro_s_1:
  sec
  sbc #$10
  bcs bcheckb_ro_s_1b
  jmp bcheckb_ro_v
bcheckb_ro_s_1b:
  tax
  and #$88
  bne bcheckb_ro_v
  lda $00, x
  and #$80
  bne bcheckb_ro_s_2
  txa
  jmp bcheckb_ro_s_1
bcheckb_ro_s_2:
  lda $00, x
  and #%11001111
  sta VLC
  cmp #wr
  beq bcheckb_ro_s_3
  lda VLC
  cmp #wq
  beq bcheckb_ro_s_3
  jmp bcheckb_ro_v
bcheckb_ro_s_3:
  stx VLD
  ldx CKC
  inx
  stx CKC

  lda BKP
  sec
  sbc #$10
  tax
bcheckb_ro_s_4:
  iny
  stx $00, y
  cmp VLD
  beq bcheckb_ro_s_5
  txa
  sec
  sbc #$10
  tax
  jmp bcheckb_ro_s_4
bcheckb_ro_s_5:
  jmp bcheckb_ro_end


;**********************************************************


bcheckb_ro_v:
  lda BKP
bcheckb_ro_v_1:
  sec
  sbc #$01
  bcs bcheckb_ro_v_1b
  jmp bcheckb_ro_end
bcheckb_ro_v_1b:
  tax
  and #$88
  bne bcheckb_ro_end
  lda $00, x
  and #$80
  bne bcheckb_ro_v_2
  txa
  jmp bcheckb_ro_v_1
bcheckb_ro_v_2:
  lda $00, x
  and #%11001111
  sta VLC
  cmp #wr
  beq bcheckb_ro_v_3
  lda VLC
  cmp #wq
  beq bcheckb_ro_v_3
  jmp bcheckb_ro_end
bcheckb_ro_v_3:
  stx VLD
  ldx CKC
  inx
  stx CKC

  lda BKP
  sec
  sbc #$01
  tax
bcheckb_ro_v_4:
  iny
  stx $00, y
  cmp VLD
  beq bcheckb_ro_v_5
  txa
  sec
  sbc #$01
  tax
  jmp bcheckb_ro_v_4
bcheckb_ro_v_5:
  jmp bcheckb_ro_end

;**********************************************************


bcheckb_ro_end:
  rts


;**********************************************************


wcfkm:
  lda #$ff
  sta VLB
wcfkm1:
  ldx WKP
  clc
  adc #$0f ; move
  tax
  and #$88
  bne wcfkm2 ; in bounds?

  lda $00, x
  and #%11000000
  cmp #%10000000
  beq wcfkm2 ; not a white peice?

  stx SQR
  jsr wchecka
  lda PIN
  bne wcfkm2 ; would the king be in check on this sqr?

  lda #$00
  sta VLB
  jmp wcfkme

wcfkm2:
  ldx WKP
  clc
  adc #$10
  tax
  and #$88
  bne wcfkm3

  lda $00, x
  and #%11000000
  cmp #%10000000
  beq wcfkm3

  stx SQR
  jsr wchecka
  lda PIN
  bne wcfkm3

  lda #$00
  sta VLB
  jmp wcfkme

wcfkm3:
  ldx WKP
  clc
  adc #$11
  tax
  and #$88
  bne wcfkm4

  lda $00, x
  and #%11000000
  cmp #%10000000
  beq wcfkm4

  stx SQR
  jsr wchecka
  lda PIN
  bne wcfkm4

  lda #$00
  sta VLB
  jmp wcfkme

wcfkm4:
  ldx WKP
  clc
  adc #$01
  tax
  and #$88
  bne wcfkm5

  lda $00, x
  and #%11000000
  cmp #%10000000
  beq wcfkm5

  stx SQR
  jsr wchecka
  lda PIN
  bne wcfkm5

  lda #$00
  sta VLB
  jmp wcfkme

wcfkm5:
  ldx WKP
  sec
  sbc #$0f
  bcc wcfkm6
  tax
  and #$88
  bne wcfkm6

  lda $00, x
  and #%11000000
  cmp #%10000000
  beq wcfkm6

  stx SQR
  jsr wchecka
  lda PIN
  bne wcfkm6

  lda #$00
  sta VLB
  jmp wcfkme

wcfkm6:
  ldx WKP
  sec
  sbc #$10
  bcc wcfkm7
  tax
  and #$88
  bne wcfkm7

  lda $00, x
  and #%11000000
  cmp #%10000000
  beq wcfkm7

  stx SQR
  jsr wchecka
  lda PIN
  bne wcfkm7

  lda #$00
  sta VLB
  jmp wcfkme

wcfkm7:
  ldx WKP
  sec
  sbc #$11
  bcc wcfkm8
  tax
  and #$88
  bne wcfkm8

  lda $00, x
  and #%11000000
  cmp #%10000000
  beq wcfkm8

  stx SQR
  jsr wchecka
  lda PIN
  bne wcfkm8

  lda #$00
  sta VLB
  jmp wcfkme

wcfkm8:
  sec
  sbc #$01
  bcc wcfkme
  tax
  and #$88
  bne wcfkme

  lda $00, x
  and #%11000000
  cmp #%10000000
  beq wcfkme

  stx SQR
  jsr wchecka
  lda PIN
  bne wcfkme

  lda #$00
  sta VLB
  jmp wcfkme

wcfkme:
  rts

;**********************************************************
;**********************************************************

bcfkm:
  lda #$ff
  sta VLB
bcfkm1:
  ldx BKP
  clc
  adc #$0f ; move
  tax
  and #$88
  bne bcfkm2 ; in bounds?

  lda $00, x
  and #%11000000
  cmp #%10000000
  beq bcfkm2 ; not a black peice?

  stx SQR
  jsr bchecka
  lda PIN
  bne bcfkm2 ; would the king be in check on this sqr?

  lda #$00
  sta VLB
  jmp bcfkme

bcfkm2:
  ldx BKP
  clc
  adc #$10
  tax
  and #$88
  bne bcfkm3

  lda $00, x
  and #%11000000
  cmp #%10000000
  beq bcfkm3

  stx SQR
  jsr bchecka
  lda PIN
  bne bcfkm3

  lda #$00
  sta VLB
  jmp bcfkme

bcfkm3:
  ldx BKP
  clc
  adc #$11
  tax
  and #$88
  bne bcfkm4

  lda $00, x
  and #%11000000
  cmp #%10000000
  beq bcfkm4

  stx SQR
  jsr bchecka
  lda PIN
  bne bcfkm4

  lda #$00
  sta VLB
  jmp bcfkme

bcfkm4:
  ldx BKP
  clc
  adc #$01
  tax
  and #$88
  bne bcfkm5

  lda $00, x
  and #%11000000
  cmp #%10000000
  beq bcfkm5

  stx SQR
  jsr bchecka
  lda PIN
  bne bcfkm5

  lda #$00
  sta VLB
  jmp bcfkme

bcfkm5:
  ldx BKP
  sec
  sbc #$0f
  bcc bcfkm6
  tax
  and #$88
  bne bcfkm6

  lda $00, x
  and #%11000000
  cmp #%10000000
  beq bcfkm6

  stx SQR
  jsr bchecka
  lda PIN
  bne bcfkm6

  lda #$00
  sta VLB
  jmp bcfkme

bcfkm6:
  ldx BKP
  sec
  sbc #$10
  bcc bcfkm7
  tax
  and #$88
  bne bcfkm7

  lda $00, x
  and #%11000000
  cmp #%10000000
  beq bcfkm7

  stx SQR
  jsr bchecka
  lda PIN
  bne bcfkm7

  lda #$00
  sta VLB
  jmp bcfkme

bcfkm7:
  ldx BKP
  sec
  sbc #$11
  bcc bcfkm8
  tax
  and #$88
  bne bcfkm8

  lda $00, x
  and #%11000000
  cmp #%10000000
  beq bcfkm8

  stx SQR
  jsr bchecka
  lda PIN
  bne bcfkm8

  lda #$00
  sta VLB
  jmp bcfkme

bcfkm8:
  sec
  sbc #$01
  bcc bcfkme
  tax
  and #$88
  bne bcfkme

  lda $00, x
  and #%11000000
  cmp #%10000000
  beq bcfkme

  stx SQR
  jsr bchecka
  lda PIN
  bne bcfkme

  lda #$00
  sta VLB
  jmp bcfkme

bcfkme:
  rts

;**********************************************************
;**********************************************************
;**********************************************************

w_capable:
  tya
  pha
  jsr wable_nv
  jsr wable_ne
  jsr wable_sv
  jsr wable_se

  jsr wable_n
  jsr wable_e
  jsr wable_v
  jsr wable_s

  jsr wable_kn_vvn
  jsr wable_kn_nnv
  jsr wable_kn_nne
  jsr wable_kn_een
  jsr wable_kn_vvs
  jsr wable_kn_ssv
  jsr wable_kn_sse
  jsr wable_kn_ees

  jsr wable_pn_a
  jsr wable_pn_b
  
  rts

w_blockable:

  jsr wable_nv
  jsr wable_ne
  jsr wable_sv
  jsr wable_se

  jsr wable_n
  jsr wable_e
  jsr wable_v
  jsr wable_s

  jsr wable_kn_vvn
  jsr wable_kn_nnv
  jsr wable_kn_nne
  jsr wable_kn_een
  jsr wable_kn_vvs
  jsr wable_kn_ssv
  jsr wable_kn_sse
  jsr wable_kn_ees

  jsr wable_pn_f
  jsr wable_pn_df

  pla
  tay

  rts

;**********************************************************
;**********************************************************
;**********************************************************

b_capable:
  tya
  pha

  jsr bable_nv
  jsr bable_ne
  jsr bable_sv
  jsr bable_se

  jsr bable_n
  jsr bable_e
  jsr bable_v
  jsr bable_s

  jsr bable_kn_vvn
  jsr bable_kn_nnv
  jsr bable_kn_nne
  jsr bable_kn_een
  jsr bable_kn_vvs
  jsr bable_kn_ssv
  jsr bable_kn_sse
  jsr bable_kn_ees

  jsr bable_pn_a
  jsr bable_pn_b

  pla
  tay
  
  rts

b_blockable:
  tya
  pha

  jsr bable_nv
  jsr bable_ne
  jsr bable_sv
  jsr bable_se

  jsr bable_n
  jsr bable_e
  jsr bable_v
  jsr bable_s

  jsr bable_kn_vvn
  jsr bable_kn_nnv
  jsr bable_kn_nne
  jsr bable_kn_een
  jsr bable_kn_vvs
  jsr bable_kn_ssv
  jsr bable_kn_sse
  jsr bable_kn_ees

  jsr bable_pn_f
  jsr bable_pn_df

  pla
  tay

  rts

;**********************************************************
;**********************************************************
;**********************************************************

bable_nv:
  lda SQR
  ldy BPP
bable_nv_1:
  clc
  adc #$0f
  tax
  and #$88
  bne bable_nv_end

  lda $00, x
  and #$80
  bne bable_nv_2
  txa
  jmp bable_nv_1

bable_nv_2:
  lda $00, x
  and #$cf
  cmp #bb
  beq bable_nv_3

  lda $00, x
  and #$cf
  cmp #bq
  beq bable_nv_3

  jmp bable_nv_end

bable_nv_3:
  iny
  stx $00, y

bable_nv_end:
  sty BPP
  rts

;**********************************************************

bable_ne:
  lda SQR
  ldy BPP
bable_ne_1:
  clc
  adc #$11
  tax
  and #$88
  bne bable_ne_end

  lda $00, x
  and #$80
  bne bable_ne_2
  txa
  jmp bable_ne_1

bable_ne_2:
  lda $00, x
  and #$cf
  cmp #bb
  beq bable_ne_3

  lda $00, x
  and #$cf
  cmp #bq
  beq bable_ne_3

  jmp bable_ne_end

bable_ne_3:
  iny
  stx $00, y

bable_ne_end:
  sty BPP
  rts

;**********************************************************

bable_se:
  lda SQR
  ldy BPP
bable_se_1:
  sec
  sbc #$0f
  tax
  and #$88
  bne bable_se_end

  lda $00, x
  and #$80
  bne bable_se_2
  txa
  jmp bable_se_1

bable_se_2:
  lda $00, x
  and #$cf
  cmp #bb
  beq bable_se_3

  lda $00, x
  and #$cf
  cmp #bq
  beq bable_se_3

  jmp bable_se_end

bable_se_3:
  iny
  stx $00, y

bable_se_end:
  sty BPP
  rts


;**********************************************************

bable_sv:
  lda SQR
  ldy BPP
bable_sv_1:
  sec
  sbc #$11
  tax
  and #$88
  bne bable_sv_end

  lda $00, x
  and #$80
  bne bable_sv_2
  txa
  jmp bable_sv_1

bable_sv_2:
  lda $00, x
  and #$cf
  cmp #bb
  beq bable_sv_3

  lda $00, x
  and #$cf
  cmp #bq
  beq bable_sv_3

  jmp bable_sv_end

bable_sv_3:
  iny
  stx $00, y

bable_sv_end:
  sty BPP
  rts

;**********************************************************

bable_n:
  lda SQR
  ldy BPP
bable_n_1:
  clc
  adc #$10
  tax
  and #$88
  bne bable_n_end

  lda $00, x
  and #$80
  bne bable_n_2
  txa
  jmp bable_n_1

bable_n_2:
  lda $00, x
  and #$cf
  cmp #br
  beq bable_n_3

  lda $00, x
  and #$cf
  cmp #bq
  beq bable_n_3

  jmp bable_n_end

bable_n_3:
  iny
  stx $00, y

bable_n_end:
  sty BPP
  rts

;**********************************************************

bable_e:
  lda SQR
  ldy BPP
bable_e_1:
  clc
  adc #$01
  tax
  and #$88
  bne bable_e_end

  lda $00, x
  and #$80
  bne bable_e_2
  txa
  jmp bable_e_1

bable_e_2:
  lda $00, x
  and #$cf
  cmp #br
  beq bable_e_3

  lda $00, x
  and #$cf
  cmp #bq
  beq bable_e_3

  jmp bable_e_end

bable_e_3:
  iny
  stx $00, y

bable_e_end:
  sty BPP
  rts

;**********************************************************

bable_v:
  lda SQR
  ldy BPP
bable_v_1:
  sec
  sbc #$01
  tax
  and #$88
  bne bable_v_end

  lda $00, x
  and #$80
  bne bable_v_2
  txa
  jmp bable_v_1

bable_v_2:
  lda $00, x
  and #$cf
  cmp #br
  beq bable_v_3

  lda $00, x
  and #$cf
  cmp #bq
  beq bable_v_3

  jmp bable_v_end

bable_v_3:
  iny
  stx $00, y

bable_v_end:
  sty BPP
  rts

;**********************************************************

bable_s:
  lda SQR
  ldy BPP
bable_s_1:
  sec
  sbc #$10
  tax
  and #$88
  bne bable_s_end

  lda $00, x
  and #$80
  bne bable_s_2
  txa
  jmp bable_s_1

bable_s_2:
  lda $00, x
  and #$cf
  cmp #br
  beq bable_s_3

  lda $00, x
  and #$cf
  cmp #bq
  beq bable_s_3

  jmp bable_s_end

bable_s_3:
  iny
  stx $00, y

bable_s_end:
  sty BPP
  rts

;**********************************************************

bable_kn_nne:
  lda SQR
  ldy BPP
  clc
  adc #$21
  tax
  and #$88
  bne bable_kn_nne_end
 
  lda $00, x
  and #$cf
  cmp #bn
  bne bable_kn_nne_end

  iny
  stx $00, y

bable_kn_nne_end:
  sty BPP
  rts
  
;**********************************************************

bable_kn_nnv:
  lda SQR
  ldy BPP
  clc
  adc #$1f
  tax
  and #$88
  bne bable_kn_nnv_end
 
  lda $00, x
  and #$cf
  cmp #bn
  bne bable_kn_nnv_end

  iny
  stx $00, y

bable_kn_nnv_end:
  sty BPP
  rts

;**********************************************************

bable_kn_een:
  lda SQR
  ldy BPP
  clc
  adc #$12
  tax
  and #$88
  bne bable_kn_een_end
 
  lda $00, x
  and #$cf
  cmp #bn
  bne bable_kn_een_end

  iny
  stx $00, y

bable_kn_een_end:
  sty BPP
  rts

;**********************************************************

bable_kn_ees:
  lda SQR
  ldy BPP
  sec
  sbc #$0e
  bcc bable_kn_ees_end
  tax
  and #$88
  bne bable_kn_ees_end
 
  lda $00, x
  and #$cf
  cmp #bn
  bne bable_kn_ees_end

  iny
  stx $00, y

bable_kn_ees_end:
  sty BPP
  rts

;**********************************************************

bable_kn_sse:
  lda SQR
  ldy BPP
  sec
  sbc #$1f
  bcc bable_kn_sse_end
  tax
  and #$88
  bne bable_kn_sse_end
 
  lda $00, x
  and #$cf
  cmp #bn
  bne bable_kn_sse_end

  iny
  stx $00, y

bable_kn_sse_end:
  sty BPP
  rts

;**********************************************************

bable_kn_ssv:
  lda SQR
  ldy BPP
  sec
  sbc #$21
  bcc bable_kn_ssv_end
  tax
  and #$88
  bne bable_kn_ssv_end
 
  lda $00, x
  and #$cf
  cmp #bn
  bne bable_kn_ssv_end

  iny
  stx $00, y

bable_kn_ssv_end:
  sty BPP
  rts

;**********************************************************

bable_kn_vvs:
  lda SQR
  ldy BPP
  sec
  sbc #$12
  bcc bable_kn_vvs_end
  tax
  and #$88
  bne bable_kn_vvs_end
 
  lda $00, x
  and #$cf
  cmp #bn
  bne bable_kn_vvs_end

  iny
  stx $00, y

bable_kn_vvs_end:
  sty BPP
  rts

;**********************************************************

bable_kn_vvn:
  lda SQR
  ldy BPP
  clc
  adc #$0e
  tax
  and #$88
  bne bable_kn_vvn_end
 
  lda $00, x
  and #$cf
  cmp #bn
  bne bable_kn_vvn_end

  iny
  stx $00, y

bable_kn_vvn_end:
  sty BPP
  rts

;**********************************************************

bable_pn_a:
  lda SQR
  ldy BPP
  clc
  adc #$11
  tax
  and #$88
  bne bable_pn_a_end
 
  lda $00, x
  and #$cf
  cmp #bp
  bne bable_pn_a_end

  iny
  stx $00, y

bable_pn_a_end:
  sty BPP
  rts

;**********************************************************

bable_pn_b:
  lda SQR
  ldy BPP
  clc
  adc #$0f
  tax
  and #$88
  bne bable_pn_b_end
 
  lda $00, x
  and #$cf
  cmp #bp
  bne bable_pn_b_end

  iny
  stx $00, y

bable_pn_b_end:
  sty BPP
  rts

;**********************************************************

bable_pn_f:
  lda SQR
  ldy BPP
  clc
  adc #$10
  tax
  and #$88
  bne bable_pn_f_end
 
  lda $00, x
  and #$cf
  cmp #bp
  bne bable_pn_f_end

  iny
  stx $00, y

bable_pn_f_end:
  sty BPP
  rts

;**********************************************************

bable_pn_df:
  lda SQR
  ldy BPP
  clc
  adc #$10
  tax
  and #$88
  bne bable_pn_df_end
 
  lda $00, x
  and #$cf
  cmp #$00
  bne bable_pn_df_end

  txa
  clc
  adc #$10
  tax
  and #$88
  bne bable_pn_df_end

  lda $00, x
  and #$cf
  cmp #bp
  bne bable_pn_df_end

  lda SQR
  and #$70
  cmp #$40
  bne bable_pn_df_end

  iny
  stx $00, y

bable_pn_df_end:
  sty BPP
  rts


;**********************************************************
;**********************************************************
;**********************************************************


wable_nv:
  lda SQR
  ldy BPP
wable_nv_1:
  clc
  adc #$0f
  tax
  and #$88
  bne wable_nv_end

  lda $00, x
  and #$80
  bne wable_nv_2
  txa
  jmp wable_nv_1

wable_nv_2:
  lda $00, x
  and #$cf
  cmp #wb
  beq wable_nv_3

  lda $00, x
  and #$cf
  cmp #wq
  beq wable_nv_3

  jmp wable_nv_end

wable_nv_3:
  iny
  stx $00, y

wable_nv_end:
  sty BPP
  rts

;**********************************************************

wable_ne:
  lda SQR
  ldy BPP
wable_ne_1:
  clc
  adc #$11
  tax
  and #$88
  bne wable_ne_end

  lda $00, x
  and #$80
  bne wable_ne_2
  txa
  jmp wable_ne_1

wable_ne_2:
  lda $00, x
  and #$cf
  cmp #wb
  beq wable_ne_3

  lda $00, x
  and #$cf
  cmp #wq
  beq wable_ne_3

  jmp wable_ne_end

wable_ne_3:
  iny
  stx $00, y

wable_ne_end:
  sty BPP
  rts

;**********************************************************

wable_se:
  lda SQR
  ldy BPP
wable_se_1:
  sec
  sbc #$0f
  tax
  and #$88
  bne wable_se_end

  lda $00, x
  and #$80
  bne wable_se_2
  txa
  jmp wable_se_1

wable_se_2:
  lda $00, x
  and #$cf
  cmp #wb
  beq wable_se_3

  lda $00, x
  and #$cf
  cmp #wq
  beq wable_se_3

  jmp wable_se_end

wable_se_3:
  iny
  stx $00, y

wable_se_end:
  sty BPP
  rts


;**********************************************************

wable_sv:
  lda SQR
  ldy BPP
wable_sv_1:
  sec
  sbc #$11
  tax
  and #$88
  bne wable_sv_end

  lda $00, x
  and #$80
  bne wable_sv_2
  txa
  jmp wable_sv_1

wable_sv_2:
  lda $00, x
  and #$cf
  cmp #wb
  beq wable_sv_3

  lda $00, x
  and #$cf
  cmp #wq
  beq wable_sv_3

  jmp wable_sv_end

wable_sv_3:
  iny
  stx $00, y

wable_sv_end:
  sty BPP
  rts

;**********************************************************

wable_n:
  lda SQR
  ldy BPP
wable_n_1:
  clc
  adc #$10
  tax
  and #$88
  bne wable_n_end

  lda $00, x
  and #$80
  bne wable_n_2
  txa
  jmp wable_n_1

wable_n_2:
  lda $00, x
  and #$cf
  cmp #wr
  beq wable_n_3

  lda $00, x
  and #$cf
  cmp #wq
  beq wable_n_3

  jmp wable_n_end

wable_n_3:
  iny
  stx $00, y

wable_n_end:
  sty BPP
  rts

;**********************************************************

wable_e:
  lda SQR
  ldy BPP
wable_e_1:
  clc
  adc #$01
  tax
  and #$88
  bne wable_e_end

  lda $00, x
  and #$80
  bne wable_e_2
  txa
  jmp wable_e_1

wable_e_2:
  lda $00, x
  and #$cf
  cmp #wr
  beq wable_e_3

  lda $00, x
  and #$cf
  cmp #wq
  beq wable_e_3

  jmp wable_e_end

wable_e_3:
  iny
  stx $00, y

wable_e_end:
  sty BPP
  rts

;**********************************************************

wable_v:
  lda SQR
  ldy BPP
wable_v_1:
  sec
  sbc #$01
  tax
  and #$88
  bne wable_v_end

  lda $00, x
  and #$80
  bne wable_v_2
  txa
  jmp wable_v_1

wable_v_2:
  lda $00, x
  and #$cf
  cmp #wr
  beq wable_v_3

  lda $00, x
  and #$cf
  cmp #wq
  beq wable_v_3

  jmp wable_v_end

wable_v_3:
  iny
  stx $00, y

wable_v_end:
  sty BPP
  rts

;**********************************************************

wable_s:
  lda SQR
  ldy BPP
wable_s_1:
  sec
  sbc #$10
  tax
  and #$88
  bne wable_s_end

  lda $00, x
  and #$80
  bne wable_s_2
  txa
  jmp wable_s_1

wable_s_2:
  lda $00, x
  and #$cf
  cmp #wr
  beq wable_s_3

  lda $00, x
  and #$cf
  cmp #wq
  beq wable_s_3

  jmp wable_s_end

wable_s_3:
  iny
  stx $00, y

wable_s_end:
  sty BPP
  rts

;**********************************************************

wable_kn_nne:
  lda SQR
  ldy BPP
  clc
  adc #$21
  tax
  and #$88
  bne wable_kn_nne_end
 
  lda $00, x
  and #$cf
  cmp #wn
  bne wable_kn_nne_end

  iny
  stx $00, y

wable_kn_nne_end:
  sty BPP
  rts
  
;**********************************************************

wable_kn_nnv:
  lda SQR
  ldy BPP
  clc
  adc #$1f
  tax
  and #$88
  bne wable_kn_nnv_end
 
  lda $00, x
  and #$cf
  cmp #wn
  bne wable_kn_nnv_end

  iny
  stx $00, y

wable_kn_nnv_end:
  sty BPP
  rts

;**********************************************************

wable_kn_een:
  lda SQR
  ldy BPP
  clc
  adc #$12
  tax
  and #$88
  bne wable_kn_een_end
 
  lda $00, x
  and #$cf
  cmp #wn
  bne wable_kn_een_end

  iny
  stx $00, y

wable_kn_een_end:
  sty BPP
  rts

;**********************************************************

wable_kn_ees:
  lda SQR
  ldy BPP
  sec
  sbc #$0e
  bcc wable_kn_ees_end
  tax
  and #$88
  bne wable_kn_ees_end
 
  lda $00, x
  and #$cf
  cmp #wn
  bne wable_kn_ees_end

  iny
  stx $00, y

wable_kn_ees_end:
  sty BPP
  rts

;**********************************************************

wable_kn_sse:
  lda SQR
  ldy BPP
  sec
  sbc #$1f
  bcc wable_kn_sse_end
  tax
  and #$88
  bne wable_kn_sse_end
 
  lda $00, x
  and #$cf
  cmp #wn
  bne wable_kn_sse_end

  iny
  stx $00, y

wable_kn_sse_end:
  sty BPP
  rts

;**********************************************************

wable_kn_ssv:
  lda SQR
  ldy BPP
  sec
  sbc #$21
  bcc wable_kn_ssv_end
  tax
  and #$88
  bne wable_kn_ssv_end
 
  lda $00, x
  and #$cf
  cmp #wn
  bne wable_kn_ssv_end

  iny
  stx $00, y

wable_kn_ssv_end:
  sty BPP
  rts

;**********************************************************

wable_kn_vvs:
  lda SQR
  ldy BPP
  sec
  sbc #$12
  bcc wable_kn_vvs_end
  tax
  and #$88
  bne wable_kn_vvs_end
 
  lda $00, x
  and #$cf
  cmp #wn
  bne wable_kn_vvs_end

  iny
  stx $00, y

wable_kn_vvs_end:
  sty BPP
  rts

;**********************************************************

wable_kn_vvn:
  lda SQR
  ldy BPP
  clc
  adc #$0e
  tax
  and #$88
  bne wable_kn_vvn_end
 
  lda $00, x
  and #$cf
  cmp #wn
  bne wable_kn_vvn_end

  iny
  stx $00, y

wable_kn_vvn_end:
  sty BPP
  rts

;**********************************************************

wable_pn_a:
  lda SQR
  ldy BPP
  sec
  sbc #$11
  bcc wable_pn_a_end
  tax
  and #$88
  bne wable_pn_a_end
 
  lda $00, x
  and #$cf
  cmp #wp
  bne wable_pn_a_end

  iny
  stx $00, y

wable_pn_a_end:
  sty BPP
  rts

;**********************************************************

wable_pn_b:
  lda SQR
  ldy BPP
  sec
  sbc #$0f
  bcc wable_pn_b_end
  tax
  and #$88
  bne wable_pn_b_end
 
  lda $00, x
  and #$cf
  cmp #wp
  bne wable_pn_b_end

  iny
  stx $00, y

wable_pn_b_end:
  sty BPP
  rts

;**********************************************************

wable_pn_f:
  lda SQR
  ldy BPP
  sec
  sbc #$10
  bcc wable_pn_f_end
  tax
  and #$88
  bne wable_pn_f_end
 
  lda $00, x
  and #$cf
  cmp #wp
  bne wable_pn_f_end

  iny
  stx $00, y

wable_pn_f_end:
  sty BPP
  rts

;**********************************************************

wable_pn_df:
  lda SQR
  ldy BPP
  sec
  sbc #$10
  bcc wable_pn_df_end
  tax
  and #$88
  bne wable_pn_df_end
 
  lda $00, x
  and #$cf
  cmp #$00
  bne wable_pn_df_end

  txa
  sec
  sbc #$10
  bcc wable_pn_df_end
  tax
  and #$88
  bne wable_pn_df_end

  lda $00, x
  and #$cf
  cmp #wp
  bne wable_pn_df_end

  lda SQR
  and #$70
  cmp #$30
  bne wable_pn_df_end

  iny
  stx $00, y

wable_pn_df_end:
  sty BPP
  rts


;**********************************************************
;**********************************************************
;**********************************************************


; REST OF SUBROUTINES


;**********************************************************
;**********************************************************
;**********************************************************

w_piece_pop0:
  jsr wreset_tickers
wq_ask0:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wq
  bne wr_ask0
  jmp woption_queen0
wr_ask0:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wr
  bne wb_ask0
  jmp woption_rook0
wb_ask0:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wb
  bne wn_ask0
  jmp woption_bishop0
wn_ask0:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wn
  bne wp_ask0
  jmp woption_knight0
wp_ask0:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wp
  bne wk_ask0
  jmp woption_pawn0
wk_ask0:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wk
  bne w_piece_option_ed0
  jmp woption_king0
w_piece_option_ed0:
  jmp w_piece_option_e0

woption_queen0:
  jsr woption_n
  jsr woption_e
  jsr woption_s
  jsr woption_w
  jsr woption_ne
  jsr woption_se
  jsr woption_sw
  jsr woption_nw
  jmp w_piece_option_e0

woption_rook0:
  jsr woption_n
  jsr woption_e
  jsr woption_s
  jsr woption_w
  jmp w_piece_option_e0

woption_bishop0:
  jsr woption_ne
  jsr woption_se
  jsr woption_sw
  jsr woption_nw
  jmp w_piece_option_e0

woption_knight0:
  jsr woption_kn
  jmp w_piece_option_e0

woption_pawn0:
  jsr woption_pn_fw
  jsr woption_pn_cap_nw
  jsr woption_pn_cap_ne
  jsr woption_pn_en
  jmp w_piece_option_e0

woption_king0:
  jsr woption_ki
  jsr woption_ki_cstl
  jmp w_piece_option_e0

w_piece_option_e0:
  rts

;**********************************************************

w_piece_pop1:
  jsr wreset_tickers
wq_ask1:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wq
  bne wr_ask1
  jmp woption_queen1
wr_ask1:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wr
  bne wb_ask1
  jmp woption_rook1
wb_ask1:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wb
  bne wn_ask1
  jmp woption_bishop1
wn_ask1:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wn
  bne wp_ask1
  jmp woption_knight1
wp_ask1:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wp
  bne wk_ask1
  jmp woption_pawn1
wk_ask1:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wk
  bne w_piece_option_ed1
  jmp woption_king1
w_piece_option_ed1:
  jmp w_piece_option_e1

woption_queen1:
  jsr woption_se
  jsr woption_nw
  jmp w_piece_option_e1

woption_rook1:
  jmp w_piece_option_e1

woption_bishop1:
  jsr woption_se
  jsr woption_nw
  jmp w_piece_option_e1

woption_knight1:
  jmp w_piece_option_e1

woption_pawn1:
  jsr woption_pn_cap_nw
  jmp w_piece_option_e1

woption_king1:
  jsr woption_ki
  jmp w_piece_option_e1

w_piece_option_e1:
  rts

;**********************************************************

w_piece_pop2:
  jsr wreset_tickers
wq_ask2:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wq
  bne wr_ask2
  jmp woption_queen2
wr_ask2:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wr
  bne wb_ask2
  jmp woption_rook2
wb_ask2:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wb
  bne wn_ask2
  jmp woption_bishop2
wn_ask2:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wn
  bne wp_ask2
  jmp woption_knight2
wp_ask2:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wp
  bne wk_ask2
  jmp woption_pawn2
wk_ask2:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wk
  bne w_piece_option_ed2
  jmp woption_king2
w_piece_option_ed2:
  jmp w_piece_option_e2

woption_queen2:
  jsr woption_n
  jsr woption_s
  jmp w_piece_option_e2

woption_rook2:
  jsr woption_n
  jsr woption_s

  jmp w_piece_option_e2


woption_bishop2:
  jmp w_piece_option_e2

woption_knight2:
  jmp w_piece_option_e2

woption_pawn2:
  jsr woption_pn_fw
  jmp w_piece_option_e2

woption_king2:
  jsr woption_ki
  jmp w_piece_option_e2

w_piece_option_e2:
  rts

;**********************************************************

w_piece_pop3:
  jsr wreset_tickers
wq_ask3:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wq
  bne wr_ask3
  jmp woption_queen3
wr_ask3:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wr
  bne wb_ask3
  jmp woption_rook3
wb_ask3:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wb
  bne wn_ask3
  jmp woption_bishop3
wn_ask3:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wn
  bne wp_ask3
  jmp woption_knight3
wp_ask3:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wp
  bne wk_ask3
  jmp woption_pawn3
wk_ask3:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wk
  bne w_piece_option_ed3
  jmp woption_king3
w_piece_option_ed3:
  jmp w_piece_option_e3

woption_queen3:
  jsr woption_ne
  jsr woption_sw
  jmp w_piece_option_e3

woption_rook3:
  jmp w_piece_option_e3


woption_bishop3:
  jsr woption_ne
  jsr woption_sw

  jmp w_piece_option_e3

woption_knight3:
  jmp w_piece_option_e3

woption_pawn3:
  jsr woption_pn_cap_ne
  jmp w_piece_option_e3

woption_king3:
  jsr woption_ki
  jmp w_piece_option_e3

w_piece_option_e3:
  rts

;**********************************************************

w_piece_pop4:
  jsr wreset_tickers
wq_ask4:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wq
  bne wr_ask4
  jmp woption_queen4
wr_ask4:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wr
  bne wb_ask4
  jmp woption_rook4
wb_ask4:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wb
  bne wn_ask4
  jmp woption_bishop4
wn_ask4:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wn
  bne wp_ask4
  jmp woption_knight4
wp_ask4:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wp
  bne wk_ask4
  jmp woption_pawn4
wk_ask4:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #wk
  bne w_piece_option_ed4
  jmp woption_king4
w_piece_option_ed4:
  jmp w_piece_option_e4

woption_queen4:
  jsr woption_e
  jsr woption_w
  jmp w_piece_option_e4

woption_rook4:
  jsr woption_e
  jsr woption_w
  jmp w_piece_option_e4

woption_bishop4:
  jmp w_piece_option_e4

woption_knight4:
  jmp w_piece_option_e4

woption_pawn4:
  jmp w_piece_option_e4

woption_king4:
  jsr woption_ki
  jmp w_piece_option_e3

w_piece_option_e4:
  rts

;**********************************************************

woption_n:
  ldy OTP
  ldx SQC
woption_n_1:
  txa
  clc
  adc #$10
  tax
  and #$88
  bne woption_n_e
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_n_e
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq woption_n_2
  iny
  txa
  sta $00, y
  jmp woption_n_1
woption_n_2:
  iny
  txa
  sta $00, y
woption_n_e:
  sty OTP
  rts

;**********************************************************

woption_s:
  ldy OTP
  ldx SQC
woption_s_1:
  txa
  sec
  sbc #$10
  bcc woption_s_e
  tax
  and #$88
  bne woption_s_e
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_s_e
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq woption_s_2
  iny
  txa
  sta $00, y
  jmp woption_s_1
woption_s_2:
  iny
  txa
  sta $00, y
woption_s_e:
  sty OTP
  rts

;**********************************************************

woption_e:
  ldy OTP
  ldx SQC
woption_e_1:
  txa
  clc
  adc #$01
  tax
  and #$88
  bne woption_e_e
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_e_e
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq woption_e_2
  iny
  txa
  sta $00, y
  jmp woption_e_1
woption_e_2:
  iny
  txa
  sta $00, y
woption_e_e:
  sty OTP
  rts

;**********************************************************

woption_w:
  ldy OTP
  ldx SQC
woption_w_1:
  txa
  sec
  sbc #$01
  bcc woption_w_e
  tax
  and #$88
  bne woption_w_e
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_w_e
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq woption_w_2
  iny
  txa
  sta $00, y
  jmp woption_w_1
woption_w_2:
  iny
  txa
  sta $00, y
woption_w_e:
  sty OTP
  rts

;**********************************************************

woption_ne:
  ldy OTP
  ldx SQC
woption_ne_1:
  txa
  clc
  adc #$11
  tax
  and #$88
  bne woption_ne_e
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_ne_e
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq woption_ne_2
  iny
  txa
  sta $00, y
  jmp woption_ne_1
woption_ne_2:
  iny
  txa
  sta $00, y
woption_ne_e:
  sty OTP
  rts

;**********************************************************

woption_nw:
  ldy OTP
  ldx SQC
woption_nw_1:
  txa
  clc
  adc #$0f
  tax
  and #$88
  bne woption_nw_e
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_nw_e
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq woption_nw_2
  iny
  txa
  sta $00, y
  jmp woption_nw_1
woption_nw_2:
  iny
  txa
  sta $00, y
woption_nw_e:
  sty OTP
  rts

;**********************************************************

woption_se:
  ldy OTP
  ldx SQC
woption_se_1:
  txa
  sec
  sbc #$0f
  bcc woption_se_e
  tax
  and #$88
  bne woption_se_e
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_se_e
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq woption_se_2
  iny
  txa
  sta $00, y
  jmp woption_se_1
woption_se_2:
  iny
  txa
  sta $00, y
woption_se_e:
  sty OTP
  rts

;**********************************************************

woption_sw:
  ldy OTP
  ldx SQC
woption_sw_1:
  txa
  sec
  sbc #$11
  bcc woption_sw_e
  tax
  and #$88
  bne woption_sw_e
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_sw_e
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq woption_sw_2
  iny
  txa
  sta $00, y
  jmp woption_sw_1
woption_sw_2:
  iny
  txa
  sta $00, y
woption_sw_e:
  sty OTP
  rts

;**********************************************************

woption_kn:
  ldy OTP
woption_kn_nne:
  lda SQC
  clc
  adc #$21
  tax
  and #$88
  bne woption_kn_nnw
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_kn_nnw
  iny
  stx $00, y
woption_kn_nnw:
  lda SQC
  clc
  adc #$1f
  tax
  and #$88
  bne woption_kn_een
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_kn_een
  iny
  stx $00, y
woption_kn_een:
  lda SQC
  clc
  adc #$12
  tax
  and #$88
  bne woption_kn_ees
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_kn_ees
  iny
  stx $00, y
woption_kn_ees:
  lda SQC
  sec
  sbc #$0e
  bcc woption_kn_sse
  tax
  and #$88
  bne woption_kn_sse
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_kn_sse
  iny
  stx $00, y
woption_kn_sse:
  lda SQC
  sec
  sbc #$1f
  bcc woption_kn_ssw
  tax
  and #$88
  bne woption_kn_ssw
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_kn_ssw
  iny
  stx $00, y
woption_kn_ssw:
  lda SQC
  sec
  sbc #$21
  bcc woption_kn_wws
  tax
  and #$88
  bne woption_kn_wws
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_kn_wws
  iny
  stx $00, y
woption_kn_wws:
  lda SQC
  sec
  sbc #$12
  bcc woption_kn_wwn
  tax
  and #$88
  bne woption_kn_wwn
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_kn_wwn
  iny
  stx $00, y
woption_kn_wwn:
  lda SQC
  clc
  adc #$0e
  tax
  and #$88
  bne woption_kn_end
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_kn_end
  iny
  stx $00, y
woption_kn_end:
  sty OTP
  rts

;**********************************************************

woption_ki:
  ldy OTP
  lda WKP
  clc
  adc #$0f
  tax
  and #$88
  bne woption_ki_1
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_ki_1
  stx SQR
  jsr wchecka
  lda PIN
  bne woption_ki_1
  iny
  txa
  sta $00, y
woption_ki_1:
  lda WKP
  clc
  adc #$10
  tax
  and #$88
  bne woption_ki_2
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_ki_2
  stx SQR
  jsr wchecka
  lda PIN
  bne woption_ki_2
  iny
  txa
  sta $00, y
woption_ki_2:
  lda WKP
  clc
  adc #$11
  tax
  and #$88
  bne woption_ki_3
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_ki_3
  stx SQR
  jsr wchecka
  lda PIN
  bne woption_ki_3
  iny
  txa
  sta $00, y
woption_ki_3:
  lda WKP
  clc
  adc #$01
  tax
  and #$88
  bne woption_ki_4
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_ki_4
  stx SQR
  jsr wchecka
  lda PIN
  bne woption_ki_4
  iny
  txa
  sta $00, y
woption_ki_4:
  lda WKP
  sec
  sbc #$0f
  bcc woption_ki_5
  tax
  and #$88
  bne woption_ki_5
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_ki_5
  stx SQR
  jsr wchecka
  lda PIN
  bne woption_ki_5
  iny
  txa
  sta $00, y
woption_ki_5:
  lda WKP
  sec
  sbc #$10
  bcc woption_ki_6
  tax
  and #$88
  bne woption_ki_6
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_ki_6
  stx SQR
  jsr wchecka
  lda PIN
  bne woption_ki_6
  iny
  txa
  sta $00, y
woption_ki_6:
  lda WKP
  sec
  sbc #$11
  bcc woption_ki_7
  tax
  and #$88
  bne woption_ki_7
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_ki_7
  stx SQR
  jsr wchecka
  lda PIN
  bne woption_ki_7
  iny
  txa
  sta $00, y
woption_ki_7:
  lda WKP
  sec
  sbc #$01
  bcc woption_ki_end
  tax
  and #$88
  bne woption_ki_end
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq woption_ki_end
  stx SQR
  jsr wchecka
  lda PIN
  bne woption_ki_end
  iny
  txa
  sta $00, y
woption_ki_end:
  sty OTP
  rts

;**********************************************************

woption_ki_cstl:
  lda WCA
  bne woption_ki_cstl_1
  jmp woption_ki_cstl_e
woption_ki_cstl_1:
  lda WCA
  and #%11110000
  beq woption_ki_cstl_2
  jsr woption_ki_cstl_l
woption_ki_cstl_2:
  lda WCA
  and #%00001111
  beq woption_ki_cstl_e
  jsr woption_ki_cstl_r 
woption_ki_cstl_e:
  rts

;**********************************************************

woption_ki_cstl_l:
woption_ki_cstl_l_1:
  lda %00000001
  and #%10000000
  beq woption_ki_cstl_l_2
  jmp woption_ki_cstl_l_e
woption_ki_cstl_l_2:
  lda %00000010
  and #%10000000
  beq woption_ki_cstl_l_2b
  jmp woption_ki_cstl_l_e
woption_ki_cstl_l_2b:
  lda #%00000010
  sta SQR
  jsr wchecka
  lda PIN
  beq woption_ki_cstl_l_3
  jmp woption_ki_cstl_l_e
woption_ki_cstl_l_3:
  lda %00000011
  and #%10000000
  beq woption_ki_cstl_l_3b
  jmp woption_ki_cstl_l_e
woption_ki_cstl_l_3b:
  lda #%00000011
  sta SQR
  jsr wchecka
  lda PIN
  beq woption_ki_cstl_l_hit
  jmp woption_ki_cstl_l_e
woption_ki_cstl_l_hit:
  ldy OTP
  lda #$02
  iny
  sta $00, y
  sta CSTLL
  sty OTP
woption_ki_cstl_l_e:
  rts

;**********************************************************

woption_ki_cstl_r:
woption_ki_cstl_r_2:
  lda $05
  and #$80
  beq woption_ki_cstl_r_2b
  jmp woption_ki_cstl_r_e
woption_ki_cstl_r_2b:
  lda #$05
  sta SQR
  jsr wchecka
  lda PIN
  beq woption_ki_cstl_r_3
  jmp woption_ki_cstl_r_e
woption_ki_cstl_r_3:
  lda $06
  and #$80
  beq woption_ki_cstl_r_3b
  jmp woption_ki_cstl_r_e
woption_ki_cstl_r_3b:
  lda #$06
  sta SQR
  jsr wchecka
  lda PIN
  beq woption_ki_cstl_r_hit
  jmp woption_ki_cstl_r_e
woption_ki_cstl_r_hit:
  ldy OTP
  lda #$06
  iny
  sta $00, y
  sta CSTLR
  sty OTP
woption_ki_cstl_r_e:
  rts


;**********************************************************

woption_pn_fw:
  ldy OTP
  lda SQC
  clc
  adc #$10
  tax
  and #$88
  bne woption_pn_fw_e
  lda $00, x
  and #%10000000
  cmp #%10000000
  beq woption_pn_fw_e
  iny
  stx $00, y
  lda SQC
  and #%01110000
  cmp #%00010000
  bne woption_pn_fw_e
  txa
  clc
  adc #$10
  tax
  and #$88
  bne woption_pn_fw_e
  lda $00, x
  and #%10000000
  cmp #%10000000
  beq woption_pn_fw_e
  iny
  stx $00, y
  stx ENS
woption_pn_fw_e:
  sty OTP
  rts

woption_pn_cap_ne:
  ldy OTP
  lda SQC
  clc
  adc #$11
  tax
  and #$88
  bne woption_pn_cap_ne_e
  lda $00, x
  and #%11000000
  cmp #%11000000
  bne woption_pn_cap_ne_e
  iny
  stx $00, y
woption_pn_cap_ne_e:
  sty OTP
  rts

woption_pn_cap_nw:
  ldy OTP
  lda SQC
  clc
  adc #$0f
  tax
  and #$88
  bne woption_pn_cap_nw_e
  lda $00, x
  and #%11000000
  cmp #%11000000
  bne woption_pn_cap_nw_e
  iny
  stx $00, y
woption_pn_cap_nw_e:
  sty OTP
  rts

woption_pn_en:
  ldy OTP
  lda SQC
  tax
  and #%01110000
  cmp #%01000000
  bne woption_pn_en_e

  txa
  clc
  adc #$11
  tax
  cmp BENB
  bne woption_pn_en_1
  iny
  stx $00, y
  stx ENP
  jmp woption_pn_en_e
woption_pn_en_1:
  lda SQC
  clc
  adc #$0f
  tax
  cmp BENB
  bne woption_pn_en_e
  iny
  stx $00, y
  stx ENP
woption_pn_en_e:
  sty OTP
  rts


;**********************************************************
;**********************************************************
;**********************************************************

b_piece_pop0:
  jsr breset_tickers
bq_ask0:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bq
  bne br_ask0
  jmp boption_queen0
br_ask0:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #br
  bne bb_ask0
  jmp boption_rook0
bb_ask0:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bb
  bne bn_ask0
  jmp boption_bishop0
bn_ask0:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bn
  bne bp_ask0
  jmp boption_knight0
bp_ask0:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bp
  bne bk_ask0
  jmp boption_pawn0
bk_ask0:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bk
  bne b_piece_option_ed0
  jmp boption_king0
b_piece_option_ed0:
  jmp b_piece_option_e0

boption_queen0:
  jsr boption_n
  jsr boption_e
  jsr boption_s
  jsr boption_w
  jsr boption_ne
  jsr boption_se
  jsr boption_sw
  jsr boption_nw
  jmp b_piece_option_e0

boption_rook0:
  jsr boption_n
  jsr boption_e
  jsr boption_s
  jsr boption_w
  jmp b_piece_option_e0

boption_bishop0:
  jsr boption_ne
  jsr boption_se
  jsr boption_sw
  jsr boption_nw
  jmp b_piece_option_e0

boption_knight0:
  jsr boption_kn
  jmp b_piece_option_e0

boption_pawn0:
  jsr boption_pn_fw
  jsr boption_pn_cap_sw
  jsr boption_pn_cap_se
  jsr boption_pn_en
  jmp b_piece_option_e0

boption_king0:
  jsr boption_ki
  jsr boption_ki_cstl
  jmp b_piece_option_e0

b_piece_option_e0:
  rts

;**********************************************************

b_piece_pop1:
  jsr breset_tickers
bq_ask1:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bq
  bne br_ask1
  jmp boption_queen1
br_ask1:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #br
  bne bb_ask1
  jmp boption_rook1
bb_ask1:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bb
  bne bn_ask1
  jmp boption_bishop1
bn_ask1:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bn
  bne bp_ask1
  jmp boption_knight1
bp_ask1:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bp
  bne bk_ask1
  jmp boption_pawn1
bk_ask1:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bk
  bne b_piece_option_ed1
  jmp boption_king1
b_piece_option_ed1:
  jmp b_piece_option_e1

boption_queen1:
  jsr boption_se
  jsr boption_nw
  jmp b_piece_option_e1

boption_rook1:
  jmp b_piece_option_e1

boption_bishop1:
  jsr boption_se
  jsr boption_nw
  jmp b_piece_option_e1

boption_knight1:
  jmp b_piece_option_e1

boption_pawn1:
  jsr boption_pn_cap_se
  jmp b_piece_option_e1

boption_king1:
  jsr boption_ki
  jmp b_piece_option_e1

b_piece_option_e1:
  rts

;**********************************************************

b_piece_pop2:
  jsr breset_tickers
bq_ask2:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bq
  bne br_ask2
  jmp boption_queen2
br_ask2:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #br
  bne bb_ask2
  jmp boption_rook2
bb_ask2:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bb
  bne bn_ask2
  jmp boption_bishop2
bn_ask2:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bn
  bne bp_ask2
  jmp boption_knight2
bp_ask2:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bp
  bne bk_ask2
  jmp boption_pawn2
bk_ask2:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bk
  bne b_piece_option_ed2
  jmp boption_king2
b_piece_option_ed2:
  jmp b_piece_option_e2

boption_queen2:
  jsr boption_n
  jsr boption_s
  jmp b_piece_option_e2

boption_rook2:
  jsr boption_n
  jsr boption_s

  jmp b_piece_option_e2


boption_bishop2:
  jmp b_piece_option_e2

boption_knight2:
  jmp b_piece_option_e2

boption_pawn2:
  jsr boption_pn_fw
  jmp b_piece_option_e2

boption_king2:
  jsr boption_ki
  jmp b_piece_option_e2

b_piece_option_e2:
  rts

;**********************************************************

b_piece_pop3:
  jsr breset_tickers
bq_ask3:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bq
  bne br_ask3
  jmp boption_queen3
br_ask3:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #br
  bne bb_ask3
  jmp boption_rook3
bb_ask3:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bb
  bne bn_ask3
  jmp boption_bishop3
bn_ask3:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bn
  bne bp_ask3
  jmp boption_knight3
bp_ask3:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bp
  bne bk_ask3
  jmp boption_pawn3
bk_ask3:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bk
  bne b_piece_option_ed3
  jmp boption_king3
b_piece_option_ed3:
  jmp b_piece_option_e3

boption_queen3:
  jsr boption_ne
  jsr boption_sw
  jmp b_piece_option_e3

boption_rook3:
  jmp b_piece_option_e3


boption_bishop3:
  jsr boption_ne
  jsr boption_sw

  jmp b_piece_option_e3

boption_knight3:
  jmp b_piece_option_e3

boption_pawn3:
  jsr boption_pn_cap_sw
  jmp b_piece_option_e3

boption_king3:
  jsr boption_ki
  jmp b_piece_option_e3

b_piece_option_e3:
  rts

;**********************************************************

b_piece_pop4:
  jsr breset_tickers
bq_ask4:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bq
  bne br_ask4
  jmp boption_queen4
br_ask4:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #br
  bne bb_ask4
  jmp boption_rook4
bb_ask4:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bb
  bne bn_ask4
  jmp boption_bishop4
bn_ask4:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bn
  bne bp_ask4
  jmp boption_knight4
bp_ask4:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bp
  bne bk_ask4
  jmp boption_pawn4
bk_ask4:
  ldx SQC
  lda $00, x
  and #%11001111
  cmp #bk
  bne b_piece_option_ed4
  jmp boption_king4
b_piece_option_ed4:
  jmp b_piece_option_e4

boption_queen4:
  jsr boption_e
  jsr boption_w
  jmp b_piece_option_e4

boption_rook4:
  jsr boption_e
  jsr boption_w
  jmp b_piece_option_e4

boption_bishop4:
  jmp b_piece_option_e4

boption_knight4:
  jmp b_piece_option_e4

boption_pawn4:
  jmp b_piece_option_e4

boption_king4:
  jsr boption_ki
  jmp b_piece_option_e3

b_piece_option_e4:
  rts


;**********************************************************

boption_n:
  ldy OTP
  ldx SQC
boption_n_1:
  txa
  clc
  adc #$10
  tax
  and #$88
  bne boption_n_e
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_n_e
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq boption_n_2
  iny
  txa
  sta $00, y
  jmp boption_n_1
boption_n_2:
  iny
  txa
  sta $00, y
boption_n_e:
  sty OTP
  rts

;**********************************************************

boption_s:
  ldy OTP
  ldx SQC
boption_s_1:
  txa
  sec
  sbc #$10
  bcc boption_s_e
  tax
  and #$88
  bne boption_s_e
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_s_e
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq boption_s_2
  iny
  txa
  sta $00, y
  jmp boption_s_1
boption_s_2:
  iny
  txa
  sta $00, y
boption_s_e:
  sty OTP
  rts

;**********************************************************

boption_e:
  ldy OTP
  ldx SQC
boption_e_1:
  txa
  clc
  adc #$01
  tax
  and #$88
  bne boption_e_e
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_e_e
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq boption_e_2
  iny
  txa
  sta $00, y
  jmp boption_e_1
boption_e_2:
  iny
  txa
  sta $00, y
boption_e_e:
  sty OTP
  rts

;**********************************************************

boption_w:
  ldy OTP
  ldx SQC
boption_w_1:
  txa
  sec
  sbc #$01
  bcc boption_w_e
  tax
  and #$88
  bne boption_w_e
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_w_e
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq boption_w_2
  iny
  txa
  sta $00, y
  jmp boption_w_1
boption_w_2:
  iny
  txa
  sta $00, y
boption_w_e:
  sty OTP
  rts

;**********************************************************

boption_ne:
  ldy OTP
  ldx SQC
boption_ne_1:
  txa
  clc
  adc #$11
  tax
  and #$88
  bne boption_ne_e
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_ne_e
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq boption_ne_2
  iny
  txa
  sta $00, y
  jmp boption_ne_1
boption_ne_2:
  iny
  txa
  sta $00, y
boption_ne_e:
  sty OTP
  rts

;**********************************************************

boption_nw:
  ldy OTP
  ldx SQC
boption_nw_1:
  txa
  clc
  adc #$0f
  tax
  and #$88
  bne boption_nw_e
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_nw_e
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq boption_nw_2
  iny
  txa
  sta $00, y
  jmp boption_nw_1
boption_nw_2:
  iny
  txa
  sta $00, y
boption_nw_e:
  sty OTP
  rts

;**********************************************************

boption_se:
  ldy OTP
  ldx SQC
boption_se_1:
  txa
  sec
  sbc #$0f
  bcc boption_se_e
  tax
  and #$88
  bne boption_se_e
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_se_e
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq boption_se_2
  iny
  txa
  sta $00, y
  jmp boption_se_1
boption_se_2:
  iny
  txa
  sta $00, y
boption_se_e:
  sty OTP
  rts

;**********************************************************

boption_sw:
  ldy OTP
  ldx SQC
boption_sw_1:
  txa
  sec
  sbc #$11
  bcc boption_sw_e
  tax
  and #$88
  bne boption_sw_e
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_sw_e
  lda $00, x
  and #%11000000
  cmp #%10000000
  beq boption_sw_2
  iny
  txa
  sta $00, y
  jmp boption_sw_1
boption_sw_2:
  iny
  txa
  sta $00, y
boption_sw_e:
  sty OTP
  rts

;**********************************************************

boption_ki:
  ldy OTP
  lda BKP
  clc
  adc #$0f
  tax
  and #$88
  bne boption_ki_1
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_ki_1
  stx SQR
  jsr bchecka
  lda PIN
  bne boption_ki_1
  iny
  txa
  sta $00, y
boption_ki_1:
  lda BKP
  clc
  adc #$10
  tax
  and #$88
  bne boption_ki_2
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_ki_2
  stx SQR
  jsr bchecka
  lda PIN
  bne boption_ki_2
  iny
  txa
  sta $00, y
boption_ki_2:
  lda BKP
  clc
  adc #$11
  tax
  and #$88
  bne boption_ki_3
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_ki_3
  stx SQR
  jsr bchecka
  lda PIN
  bne boption_ki_3
  iny
  txa
  sta $00, y
boption_ki_3:
  lda BKP
  clc
  adc #$01
  tax
  and #$88
  bne boption_ki_4
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_ki_4
  stx SQR
  jsr bchecka
  lda PIN
  bne boption_ki_4
  iny
  txa
  sta $00, y
boption_ki_4:
  lda BKP
  sec
  sbc #$0f
  bcc boption_ki_5
  tax
  and #$88
  bne boption_ki_5
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_ki_5
  stx SQR
  jsr bchecka
  lda PIN
  bne boption_ki_5
  iny
  txa
  sta $00, y
boption_ki_5:
  lda BKP
  sec
  sbc #$10
  bcc boption_ki_6
  tax
  and #$88
  bne boption_ki_6
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_ki_6
  stx SQR
  jsr bchecka
  lda PIN
  bne boption_ki_6
  iny
  txa
  sta $00, y
boption_ki_6:
  lda BKP
  sec
  sbc #$11
  bcc boption_ki_7
  tax
  and #$88
  bne boption_ki_7
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_ki_7
  stx SQR
  jsr bchecka
  lda PIN
  bne boption_ki_7
  iny
  txa
  sta $00, y
boption_ki_7:
  lda BKP
  sec
  sbc #$01
  bcc boption_ki_end
  tax
  and #$88
  bne boption_ki_end
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_ki_end
  stx SQR
  jsr bchecka
  lda PIN
  bne boption_ki_end
  iny
  txa
  sta $00, y
boption_ki_end:
  sty OTP
  rts

;**********************************************************

boption_kn:
  ldy OTP
boption_kn_nne:
  lda SQC
  clc
  adc #$21
  tax
  and #$88
  bne boption_kn_nnw
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_kn_nnw
  iny
  stx $00, y
boption_kn_nnw:
  lda SQC
  clc
  adc #$1f
  tax
  and #$88
  bne boption_kn_een
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_kn_een
  iny
  stx $00, y
boption_kn_een:
  lda SQC
  clc
  adc #$12
  tax
  and #$88
  bne boption_kn_ees
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_kn_ees
  iny
  stx $00, y
boption_kn_ees:
  lda SQC
  sec
  sbc #$0e
  bcc boption_kn_sse
  tax
  and #$88
  bne boption_kn_sse
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_kn_sse
  iny
  stx $00, y
boption_kn_sse:
  lda SQC
  sec
  sbc #$1f
  bcc boption_kn_ssw
  tax
  and #$88
  bne boption_kn_ssw
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_kn_ssw
  iny
  stx $00, y
boption_kn_ssw:
  lda SQC
  sec
  sbc #$21
  bcc boption_kn_wws
  tax
  and #$88
  bne boption_kn_wws
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_kn_wws
  iny
  stx $00, y
boption_kn_wws:
  lda SQC
  sec
  sbc #$12
  bcc boption_kn_wwn
  tax
  and #$88
  bne boption_kn_wwn
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_kn_wwn
  iny
  stx $00, y
boption_kn_wwn:
  lda SQC
  clc
  adc #$0e
  tax
  and #$88
  bne boption_kn_end
  lda $00, x
  and #%11000000
  cmp #%11000000
  beq boption_kn_end
  iny
  stx $00, y
boption_kn_end:
  sty OTP
  rts

;**********************************************************

boption_pn_fw:
  ldy OTP
  lda SQC
  sec
  sbc #$10
  bcc boption_pn_fw_e
  tax
  and #$88
  bne boption_pn_fw_e
  lda $00, x
  and #%10000000
  cmp #%10000000
  beq boption_pn_fw_e
  iny
  stx $00, y
  lda SQC
  and #%01110000
  cmp #%01100000
  bne boption_pn_fw_e
  txa
  sec
  sbc #$10
  bcc boption_pn_fw_e
  tax
  and #$88
  bne boption_pn_fw_e
  lda $00, x
  and #%10000000
  cmp #%10000000
  beq boption_pn_fw_e
  iny
  stx $00, y
  stx ENS
boption_pn_fw_e:
  sty OTP
  rts

boption_pn_cap_se:
  ldy OTP
  lda SQC
  sec
  sbc #$0f
  bcc boption_pn_cap_se_e
  tax
  and #$88
  bne boption_pn_cap_se_e
  lda $00, x
  and #%11000000
  cmp #%10000000
  bne boption_pn_cap_se_e
  iny
  stx $00, y
boption_pn_cap_se_e:
  sty OTP
  rts

boption_pn_cap_sw:
  ldy OTP
  lda SQC
  sec
  sbc #$11
  bcc boption_pn_cap_sw_e
  tax
  and #$88
  bne boption_pn_cap_sw_e
  lda $00, x
  and #%11000000
  cmp #%10000000
  bne boption_pn_cap_sw_e
  iny
  stx $00, y
boption_pn_cap_sw_e:
  sty OTP
  rts

boption_pn_en:
  ldy OTP
  lda SQC
  tax
  and #%01110000
  cmp #%00110000
  bne boption_pn_en_e

  txa
  sec
  sbc #$11
  tax
  cmp WENB
  bne boption_pn_en_1
  iny
  stx $00, y
  stx ENP
  jmp boption_pn_en_e
boption_pn_en_1:
  lda SQC
  sec
  sbc #$0f
  tax
  cmp WENB
  bne boption_pn_en_e
  iny
  stx $00, y
  stx ENP
boption_pn_en_e:
  sty OTP
  rts


;**********************************************************
;**********************************************************
;**********************************************************

wchecka:
  txa
  pha
  lda #$00
  sta PIN
  ldx WKP
  lda #$00
  sta $00, x
  jsr wchecka_kn
  lda PIN
  bne wchecka_e

  jsr wchecka_pn
  lda PIN
  bne wchecka_e

  jsr wchecka_ki
  lda PIN
  bne wchecka_e

  jsr wchecka_bi
  lda PIN 
  bne wchecka_e

  jsr wchecka_ro
  lda PIN
  bne wchecka_e
wchecka_e:
  ldx WKP
  lda #%10001000
  sta $00, x
  pla
  tax
  rts
;**********************************************************

wchecka_kn:
  lda SQR
  clc
  adc #$21
  tax
  and #$88
  bne wchecka_kn_1
  lda $00, x
  and #%11001111
  cmp #%11000001
  bne wchecka_kn_1
  jmp wchecka_kn_hit
wchecka_kn_1:
  lda SQR
  clc
  adc #$1f
  tax
  and #$88
  bne wchecka_kn_2
  lda $00, x
  and #%11001111
  cmp #%11000001
  bne wchecka_kn_2
  jmp wchecka_kn_hit
wchecka_kn_2:
  lda SQR
  clc
  adc #$12
  tax
  and #$88
  bne wchecka_kn_3
  lda $00, x
  and #%11001111
  cmp #%11000001
  bne wchecka_kn_3
  jmp wchecka_kn_hit
wchecka_kn_3:
  lda SQR
  clc
  adc #$0e
  tax
  and #$88
  bne wchecka_kn_4
  lda $00, x
  and #%11001111
  cmp #%11000001
  bne wchecka_kn_4
  jmp wchecka_kn_hit
wchecka_kn_4:
  lda SQR
  sec
  sbc #$21
  bcc wchecka_kn_5
  tax
  and #$88
  bne wchecka_kn_5
  lda $00, x
  and #%11001111
  cmp #%11000001
  bne wchecka_kn_5
  jmp wchecka_kn_hit
wchecka_kn_5:
  lda SQR
  sec
  sbc #$12
  bcc wchecka_kn_6
  tax
  and #$88
  bne wchecka_kn_6
  lda $00, x
  and #%11001111
  cmp #%11000001
  bne wchecka_kn_6
  jmp wchecka_kn_hit
wchecka_kn_6:
  lda SQR
  sec
  sbc #$0e
  bcc wchecka_kn_7
  tax
  and #$88
  bne wchecka_kn_7
  lda $00, x
  and #%11001111
  cmp #%11000001
  bne wchecka_kn_7
  jmp wchecka_kn_hit
wchecka_kn_7:
  lda SQR
  sec
  sbc #$1f
  bcc wchecka_kn_e
  tax
  and #$88
  bne wchecka_kn_e
  lda $00, x
  and #%11001111
  cmp #%11000001
  bne wchecka_kn_e
  jmp wchecka_kn_hit
wchecka_kn_hit:
  lda #$ff
  sta PIN
wchecka_kn_e:
  rts

;**********************************************************

wchecka_pn:
  lda SQR
  clc
  adc #$11
  tax
  and #$88
  bne wchecka_pn_1
  lda $00, x
  and #%11001111
  cmp #%11000000
  bne wchecka_pn_1
  jmp wchecka_pn_hit
wchecka_pn_1:
  lda SQR
  clc
  adc #$0f
  tax
  and #$88
  bne wchecka_pn_e
  lda $00, x
  and #%11001111
  cmp #%11000000
  bne wchecka_pn_e
  jmp wchecka_pn_hit
wchecka_pn_hit:
  lda #$ff
  sta PIN
wchecka_pn_e:
  rts

;**********************************************************

wchecka_ki:
  lda SQR
  clc 
  adc #$0f
  cmp BKP
  bne wchecka_ki_1
  jmp wchecka_ki_hit
wchecka_ki_1:
  lda SQR
  clc 
  adc #$10
  cmp BKP
  bne wchecka_ki_2
  jmp wchecka_ki_hit
wchecka_ki_2:
  lda SQR
  clc 
  adc #$11
  cmp BKP
  bne wchecka_ki_3
  jmp wchecka_ki_hit
wchecka_ki_3:
  lda SQR
  clc 
  adc #$01
  cmp BKP
  bne wchecka_ki_4
  jmp wchecka_ki_hit
wchecka_ki_4:
  lda SQR
  sec 
  sbc #$0f
  bcc wchecka_ki_5
  cmp BKP
  bne wchecka_ki_5
  jmp wchecka_ki_hit
wchecka_ki_5:
  lda SQR
  sec 
  sbc #$10
  bcc wchecka_ki_6
  cmp BKP
  bne wchecka_ki_6
  jmp wchecka_ki_hit
wchecka_ki_6:
  lda SQR
  sec 
  sbc #$11
  bcc wchecka_ki_7
  cmp BKP
  bne wchecka_ki_7
  jmp wchecka_ki_hit
wchecka_ki_7:
  lda SQR
  sec 
  sbc #$01
  bcc wchecka_ki_e
  cmp BKP
  bne wchecka_ki_e
  jmp wchecka_ki_hit
wchecka_ki_hit:
  lda #$ff
  sta PIN
wchecka_ki_e:
  rts

;**********************************************************

wchecka_bi:
wchecka_bi_ne:
  lda SQR
wchecka_bi_ne_1:
  clc
  adc #$11
  tax
  and #$88
  bne wchecka_bi_nw
  lda $00, x
  and #$80
  bne wchecka_bi_ne_2
  txa
  jmp wchecka_bi_ne_1
wchecka_bi_ne_2:
  lda $00, x
  and #%11000010
  cmp #%11000010
  bne wchecka_bi_nw
  jmp wchecka_bi_hit

wchecka_bi_nw:
  lda SQR
wchecka_bi_nw_1:
  clc
  adc #$0f
  tax
  and #$88
  bne wchecka_bi_se
  lda $00, x
  and #$80
  bne wchecka_bi_nw_2
  txa
  jmp wchecka_bi_nw_1
wchecka_bi_nw_2:
  lda $00, x
  and #%11000010
  cmp #%11000010
  bne wchecka_bi_se
  jmp wchecka_bi_hit

wchecka_bi_se:
  lda SQR
wchecka_bi_se_1:
  sec
  sbc #$0f
  bcc wchecka_bi_sw
  tax
  and #$88
  bne wchecka_bi_sw
  lda $00, x
  and #$80
  bne wchecka_bi_se_2
  txa
  jmp wchecka_bi_se_1
wchecka_bi_se_2:
  lda $00, x
  and #%11000010
  cmp #%11000010
  bne wchecka_bi_sw
  jmp wchecka_bi_hit

wchecka_bi_sw:
  lda SQR
wchecka_bi_sw_1:
  sec
  sbc #$11
  bcc wchecka_bi_e
  tax
  and #$88
  bne wchecka_bi_e
  lda $00, x
  and #$80
  bne wchecka_bi_sw_2
  txa
  jmp wchecka_bi_sw_1
wchecka_bi_sw_2:
  lda $00, x
  and #%11000010
  cmp #%11000010
  bne wchecka_bi_e
  jmp wchecka_bi_hit
wchecka_bi_hit:
  lda #$ff
  sta PIN
wchecka_bi_e:
  rts

;**********************************************************

wchecka_ro:
wchecka_ro_n:
  lda SQR
wchecka_ro_n_1:
  clc
  adc #$10
  tax
  and #$88
  bne wchecka_ro_e
  lda $00, x
  and #$80
  bne wchecka_ro_n_2
  txa
  jmp wchecka_ro_n_1
wchecka_ro_n_2:
  lda $00, x
  and #%11000100
  cmp #%11000100
  bne wchecka_ro_e
  jmp wchecka_ro_hit

wchecka_ro_e:
  lda SQR
wchecka_ro_e_1:
  clc
  adc #$01
  tax
  and #$88
  bne wchecka_ro_s
  lda $00, x
  and #$80
  bne wchecka_ro_e_2
  txa
  jmp wchecka_ro_e_1
wchecka_ro_e_2:
  lda $00, x
  and #%11000100
  cmp #%11000100
  bne wchecka_ro_s
  jmp wchecka_ro_hit

wchecka_ro_s:
  lda SQR
wchecka_ro_s_1:
  sec
  sbc #$10
  bcc wchecka_ro_w
  tax
  and #$88
  bne wchecka_ro_w
  lda $00, x
  and #$80
  bne wchecka_ro_s_2
  txa
  jmp wchecka_ro_s_1
wchecka_ro_s_2:
  lda $00, x
  and #%11000100
  cmp #%11000100
  bne wchecka_ro_w
  jmp wchecka_ro_hit

wchecka_ro_w:
  lda SQR
wchecka_ro_w_1:
  sec
  sbc #$01
  bcc wchecka_ro_end
  tax
  and #$88
  bne wchecka_ro_end
  lda $00, x
  and #$80
  bne wchecka_ro_w_2
  txa
  jmp wchecka_ro_w_1
wchecka_ro_w_2:
  lda $00, x
  and #%11000100
  cmp #%11000100
  bne wchecka_ro_end
  jmp wchecka_ro_hit
wchecka_ro_hit:
  lda #$ff
  sta PIN
wchecka_ro_end:
  rts

;**********************************************************
;**********************************************************
;**********************************************************

bchecka:
  txa
  pha
  lda #$00
  sta PIN
  ldx BKP
  lda #$00
  sta $00, x
  jsr bchecka_kn
  lda PIN
  bne bchecka_e

  jsr bchecka_pn
  lda PIN
  bne bchecka_e

  jsr bchecka_ki
  lda PIN
  bne bchecka_e

  jsr bchecka_bi
  lda PIN 
  bne bchecka_e

  jsr bchecka_ro
  lda PIN
  bne bchecka_e
bchecka_e:
  ldx BKP
  lda #%11001000
  sta $00, x
  pla
  tax
  rts
;**********************************************************

bchecka_kn:
  lda SQR
  clc
  adc #$21
  tax
  and #$88
  bne bchecka_kn_1
  lda $00, x
  and #%11001111
  cmp #%10000001
  bne bchecka_kn_1
  jmp bchecka_kn_hit
bchecka_kn_1:
  lda SQR
  clc
  adc #$1f
  tax
  and #$88
  bne bchecka_kn_2
  lda $00, x
  and #%11001111
  cmp #%10000001
  bne bchecka_kn_2
  jmp bchecka_kn_hit
bchecka_kn_2:
  lda SQR
  clc
  adc #$12
  tax
  and #$88
  bne bchecka_kn_3
  lda $00, x
  and #%11001111
  cmp #%10000001
  bne bchecka_kn_3
  jmp bchecka_kn_hit
bchecka_kn_3:
  lda SQR
  clc
  adc #$0e
  tax
  and #$88
  bne bchecka_kn_4
  lda $00, x
  and #%11001111
  cmp #%10000001
  bne bchecka_kn_4
  jmp bchecka_kn_hit
bchecka_kn_4:
  lda SQR
  sec
  sbc #$21
  bcc bchecka_kn_5
  tax
  and #$88
  bne bchecka_kn_5
  lda $00, x
  and #%11001111
  cmp #%10000001
  bne bchecka_kn_5
  jmp bchecka_kn_hit
bchecka_kn_5:
  lda SQR
  sec
  sbc #$12
  bcc bchecka_kn_6
  tax
  and #$88
  bne bchecka_kn_6
  lda $00, x
  and #%11001111
  cmp #%10000001
  bne bchecka_kn_6
  jmp bchecka_kn_hit
bchecka_kn_6:
  lda SQR
  sec
  sbc #$0e
  bcc bchecka_kn_7
  tax
  and #$88
  bne bchecka_kn_7
  lda $00, x
  and #%11001111
  cmp #%10000001
  bne bchecka_kn_7
  jmp bchecka_kn_hit
bchecka_kn_7:
  lda SQR
  sec
  sbc #$1f
  bcc bchecka_kn_e
  tax
  and #$88
  bne bchecka_kn_e
  lda $00, x
  and #%11001111
  cmp #%10000001
  bne bchecka_kn_e
  jmp bchecka_kn_hit
bchecka_kn_hit:
  lda #$ff
  sta PIN
bchecka_kn_e:
  rts

;**********************************************************

bchecka_pn:
  lda SQR
  sec
  sbc #$11
  bcc bchecka_pn_1
  tax
  and #$88
  bne bchecka_pn_1
  lda $00, x
  and #%11001111
  cmp #%10000000
  bne bchecka_pn_1
  jmp bchecka_pn_hit
bchecka_pn_1:
  lda SQR
  sec
  sbc #$0f
  bcc bchecka_pn_e
  tax
  and #$88
  bne bchecka_pn_e
  lda $00, x
  and #%11001111
  cmp #%10000000
  bne bchecka_pn_e
  jmp bchecka_pn_hit
bchecka_pn_hit:
  lda #$ff
  sta PIN
bchecka_pn_e:
  rts

;**********************************************************

bchecka_ki:
  lda SQR
  clc 
  adc #$0f
  cmp WKP
  bne bchecka_ki_1
  jmp bchecka_ki_hit
bchecka_ki_1:
  lda SQR
  clc 
  adc #$10
  cmp WKP
  bne bchecka_ki_2
  jmp bchecka_ki_hit
bchecka_ki_2:
  lda SQR
  clc 
  adc #$11
  cmp WKP
  bne bchecka_ki_3
  jmp bchecka_ki_hit
bchecka_ki_3:
  lda SQR
  clc 
  adc #$01
  cmp WKP
  bne bchecka_ki_4
  jmp bchecka_ki_hit
bchecka_ki_4:
  lda SQR
  sec 
  sbc #$0f
  bcc bchecka_ki_5
  cmp WKP
  bne bchecka_ki_5
  jmp bchecka_ki_hit
bchecka_ki_5:
  lda SQR
  sec 
  sbc #$10
  bcc bchecka_ki_6
  cmp WKP
  bne bchecka_ki_6
  jmp bchecka_ki_hit
bchecka_ki_6:
  lda SQR
  sec 
  sbc #$11
  bcc bchecka_ki_7
  cmp WKP
  bne bchecka_ki_7
  jmp bchecka_ki_hit
bchecka_ki_7:
  lda SQR
  sec 
  sbc #$01
  bcc bchecka_ki_e
  cmp WKP
  bne bchecka_ki_e
  jmp bchecka_ki_hit
bchecka_ki_hit:
  lda #$ff
  sta PIN
bchecka_ki_e:
  rts

;**********************************************************
;**********************************************************
;**********************************************************

wcif:
  lda #$00
  sta PIN

wcif_nw:
  ldx SQR
wcif_nw_1:
  txa
  clc
  adc #$0f
  tax
  and #$88
  beq wcif_nw_2
  jmp wcif_n
wcif_nw_2:
  lda $00, x
  and #$80
  bne wcif_nw_3
  jmp wcif_nw_1
wcif_nw_3:
  txa
  cmp WKP
  beq wcif_nw_4
  jmp wcif_n
wcif_nw_4:
  ldx SQR
wcif_nw_5:
  txa
  sec
  sbc #$0f
  tax
  bcc wcif_nw_8
  and #$88
  beq wcif_nw_6
  jmp wcif_end
wcif_nw_6:
  lda $00, x
  and #$80
  bne wcif_nw_7
  jmp wcif_nw_5
wcif_nw_7:
  lda $00, x
  and #%11000010
  cmp #%11000010
  bne wcif_nw_8
  lda #%10000000
  sta PIN
wcif_nw_8:
  jmp wcif_end

wcif_n:
  ldx SQR
wcif_n_1:
  txa
  clc
  adc #$10
  tax
  and #$88
  beq wcif_n_2
  jmp wcif_ne
wcif_n_2:
  lda $00, x
  and #$80
  bne wcif_n_3
  jmp wcif_n_1
wcif_n_3:
  txa
  cmp WKP
  beq wcif_n_4
  jmp wcif_ne
wcif_n_4:
  ldx SQR
wcif_n_5:
  txa
  sec
  sbc #$10
  tax
  bcc wcif_n_8
  and #$88
  beq wcif_n_6
  jmp wcif_end
wcif_n_6:
  lda $00, x
  and #$80
  bne wcif_n_7
  jmp wcif_n_5
wcif_n_7:
  lda $00, x
  and #%11000100
  cmp #%11000100
  bne wcif_n_8
  lda #%01000000
  sta PIN
wcif_n_8:
  jmp wcif_end

wcif_ne:
  ldx SQR
wcif_ne_1:
  txa
  clc
  adc #$11
  tax
  and #$88
  beq wcif_ne_2
  jmp wcif_e
wcif_ne_2:
  lda $00, x
  and #$80
  bne wcif_ne_3
  jmp wcif_ne_1
wcif_ne_3:
  txa
  cmp WKP
  beq wcif_ne_4
  jmp wcif_e
wcif_ne_4:
  ldx SQR
wcif_ne_5:
  txa
  sec
  sbc #$11
  tax
  bcc wcif_ne_8
  and #$88
  beq wcif_ne_6
  jmp wcif_end
wcif_ne_6:
  lda $00, x
  and #$80
  bne wcif_ne_7
  jmp wcif_ne_5
wcif_ne_7:
  lda $00, x
  and #%11000010
  cmp #%11000010
  bne wcif_ne_8
  lda #%00100000
  sta PIN
wcif_ne_8:
  jmp wcif_end

wcif_e:
  ldx SQR
wcif_e_1:
  txa
  clc
  adc #$01
  tax
  and #$88
  beq wcif_e_2
  jmp wcif_se
wcif_e_2:
  lda $00, x
  and #$80
  bne wcif_e_3
  jmp wcif_e_1
wcif_e_3:
  txa
  cmp WKP
  beq wcif_e_4
  jmp wcif_se
wcif_e_4:
  ldx SQR
wcif_e_5:
  txa
  sec
  sbc #$01
  tax
  bcc wcif_e_8
  and #$88
  beq wcif_e_6
  jmp wcif_end
wcif_e_6:
  lda $00, x
  and #$80
  bne wcif_e_7
  jmp wcif_e_5
wcif_e_7:
  lda $00, x
  and #%11000100
  cmp #%11000100
  bne wcif_e_8
  lda #%00010000
  sta PIN
wcif_e_8:
  jmp wcif_end

wcif_se:
  ldx SQR
wcif_se_1:
  txa
  sec
  sbc #$0f
  tax
  bcc wcif_se_3
  and #$88
  beq wcif_se_2
  jmp wcif_s
wcif_se_2:
  lda $00, x
  and #$80
  bne wcif_se_3
  jmp wcif_se_1
wcif_se_3:
  txa
  cmp WKP
  beq wcif_se_4
  jmp wcif_s
wcif_se_4:
  ldx SQR
wcif_se_5:
  txa
  clc
  adc #$0f
  tax
  and #$88
  beq wcif_se_6
  jmp wcif_end
wcif_se_6:
  lda $00, x
  and #$80
  bne wcif_se_7
  jmp wcif_se_5
wcif_se_7:
  lda $00, x
  and #%11000010
  cmp #%11000010
  bne wcif_se_8
  lda #%10000000
  sta PIN
wcif_se_8:
  jmp wcif_end

wcif_s:
  ldx SQR
wcif_s_1:
  txa
  sec
  sbc #$10
  tax
  bcc wcif_s_3
  and #$88
  beq wcif_s_2
  jmp wcif_sw
wcif_s_2:
  lda $00, x
  and #$80
  bne wcif_s_3
  jmp wcif_s_1
wcif_s_3:
  txa
  cmp WKP
  beq wcif_s_4
  jmp wcif_sw
wcif_s_4:
  ldx SQR
wcif_s_5:
  txa
  clc
  adc #$10
  tax
  and #$88
  beq wcif_s_6
  jmp wcif_end
wcif_s_6:
  lda $00, x
  and #$80
  bne wcif_s_7
  jmp wcif_s_5
wcif_s_7:
  lda $00, x
  and #%11000100
  cmp #%11000100
  bne wcif_s_8
  lda #%01000000
  sta PIN
wcif_s_8:
  jmp wcif_end

wcif_sw:
  ldx SQR
wcif_sw_1:
  txa
  sec
  sbc #$11
  tax
  bcc wcif_sw_3
  and #$88
  beq wcif_sw_2
  jmp wcif_w
wcif_sw_2:
  lda $00, x
  and #$80
  bne wcif_sw_3
  jmp wcif_sw_1
wcif_sw_3:
  txa
  cmp WKP
  beq wcif_sw_4
  jmp wcif_w
wcif_sw_4:
  ldx SQR
wcif_sw_5:
  txa
  clc
  adc #$11
  tax
  and #$88
  beq wcif_sw_6
  jmp wcif_end
wcif_sw_6:
  lda $00, x
  and #$80
  bne wcif_sw_7
  jmp wcif_sw_5
wcif_sw_7:
  lda $00, x
  and #%11000010
  cmp #%11000010
  bne wcif_sw_8
  lda #%00100000
  sta PIN
wcif_sw_8:
  jmp wcif_end

wcif_w:
  ldx SQR
wcif_w_1:
  txa
  sec
  sbc #$01
  tax
  bcc wcif_w_3
  and #$88
  beq wcif_w_2
  jmp wcif_end
wcif_w_2:
  lda $00, x
  and #$80
  bne wcif_w_3
  jmp wcif_w_1
wcif_w_3:
  txa
  cmp WKP
  beq wcif_w_4
  jmp wcif_end
wcif_w_4:
  ldx SQR
wcif_w_5:
  txa
  clc
  adc #$01
  tax
  and #$88
  beq wcif_w_6
  jmp wcif_end
wcif_w_6:
  lda $00, x
  and #$80
  bne wcif_w_7
  jmp wcif_w_5
wcif_w_7:
  lda $00, x
  and #%11000100
  cmp #%11000100
  bne wcif_w_8
  lda #%00010000
  sta PIN
wcif_w_8:
  jmp wcif_end

wcif_end:
  rts

;**********************************************************
;**********************************************************
;**********************************************************

bcif:
  lda #$00
  sta PIN

bcif_nw:
  ldx SQR
bcif_nw_1:
  txa
  clc
  adc #$0f
  tax
  and #$88
  beq bcif_nw_2
  jmp bcif_n
bcif_nw_2:
  lda $00, x
  and #$80
  bne bcif_nw_3
  jmp bcif_nw_1
bcif_nw_3:
  txa
  cmp BKP
  beq bcif_nw_4
  jmp bcif_n
bcif_nw_4:
  ldx SQR
bcif_nw_5:
  txa
  sec
  sbc #$0f
  tax
  bcc bcif_nw_8
  and #$88
  beq bcif_nw_6
  jmp bcif_end
bcif_nw_6:
  lda $00, x
  and #$80
  bne bcif_nw_7
  jmp bcif_nw_5
bcif_nw_7:
  lda $00, x
  and #%11000010
  cmp #%10000010
  bne bcif_nw_8
  lda #%10000000
  sta PIN
bcif_nw_8:
  jmp bcif_end

bcif_n:
  ldx SQR
bcif_n_1:
  txa
  clc
  adc #$10
  tax
  and #$88
  beq bcif_n_2
  jmp bcif_ne
bcif_n_2:
  lda $00, x
  and #$80
  bne bcif_n_3
  jmp bcif_n_1
bcif_n_3:
  txa
  cmp BKP
  beq bcif_n_4
  jmp bcif_ne
bcif_n_4:
  ldx SQR
bcif_n_5:
  txa
  sec
  sbc #$10
  tax
  bcc bcif_n_8
  and #$88
  beq bcif_n_6
  jmp bcif_end
bcif_n_6:
  lda $00, x
  and #$80
  bne bcif_n_7
  jmp bcif_n_5
bcif_n_7:
  lda $00, x
  and #%11000100
  cmp #%10000100
  bne bcif_n_8
  lda #%01000000
  sta PIN
bcif_n_8:
  jmp bcif_end

bcif_ne:
  ldx SQR
bcif_ne_1:
  txa
  clc
  adc #$11
  tax
  and #$88
  beq bcif_ne_2
  jmp bcif_e
bcif_ne_2:
  lda $00, x
  and #$80
  bne bcif_ne_3
  jmp bcif_ne_1
bcif_ne_3:
  txa
  cmp BKP
  beq bcif_ne_4
  jmp bcif_e
bcif_ne_4:
  ldx SQR
bcif_ne_5:
  txa
  sec
  sbc #$11
  tax
  bcc bcif_ne_8
  and #$88
  beq bcif_ne_6
  jmp bcif_end
bcif_ne_6:
  lda $00, x
  and #$80
  bne bcif_ne_7
  jmp bcif_ne_5
bcif_ne_7:
  lda $00, x
  and #%11000010
  cmp #%10000010
  bne bcif_ne_8
  lda #%00100000
  sta PIN
bcif_ne_8:
  jmp bcif_end

bcif_e:
  ldx SQR
bcif_e_1:
  txa
  clc
  adc #$01
  tax
  and #$88
  beq bcif_e_2
  jmp bcif_se
bcif_e_2:
  lda $00, x
  and #$80
  bne bcif_e_3
  jmp bcif_e_1
bcif_e_3:
  txa
  cmp BKP
  beq bcif_e_4
  jmp bcif_se
bcif_e_4:
  ldx SQR
bcif_e_5:
  txa
  sec
  sbc #$01
  tax
  bcc bcif_e_8
  and #$88
  beq bcif_e_6
  jmp bcif_end
bcif_e_6:
  lda $00, x
  and #$80
  bne bcif_e_7
  jmp bcif_e_5
bcif_e_7:
  lda $00, x
  and #%11000100
  cmp #%10000100
  bne bcif_e_8
  lda #%00010000
  sta PIN
bcif_e_8:
  jmp bcif_end

bcif_se:
  ldx SQR
bcif_se_1:
  txa
  sec
  sbc #$0f
  tax
  bcc bcif_se_3
  and #$88
  beq bcif_se_2
  jmp bcif_s
bcif_se_2:
  lda $00, x
  and #$80
  bne bcif_se_3
  jmp bcif_se_1
bcif_se_3:
  txa
  cmp BKP
  beq bcif_se_4
  jmp bcif_s
bcif_se_4:
  ldx SQR
bcif_se_5:
  txa
  clc
  adc #$0f
  tax
  and #$88
  beq bcif_se_6
  jmp bcif_end
bcif_se_6:
  lda $00, x
  and #$80
  bne bcif_se_7
  jmp bcif_se_5
bcif_se_7:
  lda $00, x
  and #%11000010
  cmp #%10000010
  bne bcif_se_8
  lda #%10000000
  sta PIN
bcif_se_8:
  jmp bcif_end

bcif_s:
  ldx SQR
bcif_s_1:
  txa
  sec
  sbc #$10
  tax
  bcc bcif_s_3
  and #$88
  beq bcif_s_2
  jmp bcif_sw
bcif_s_2:
  lda $00, x
  and #$80
  bne bcif_s_3
  jmp bcif_s_1
bcif_s_3:
  txa
  cmp BKP
  beq bcif_s_4
  jmp bcif_sw
bcif_s_4:
  ldx SQR
bcif_s_5:
  txa
  clc
  adc #$10
  tax
  and #$88
  beq bcif_s_6
  jmp bcif_end
bcif_s_6:
  lda $00, x
  and #$80
  bne bcif_s_7
  jmp bcif_s_5
bcif_s_7:
  lda $00, x
  and #%11000100
  cmp #%10000100
  bne bcif_s_8
  lda #%01000000
  sta PIN
bcif_s_8:
  jmp bcif_end

bcif_sw:
  ldx SQR
bcif_sw_1:
  txa
  sec
  sbc #$11
  tax
  bcc bcif_sw_3
  and #$88
  beq bcif_sw_2
  jmp bcif_w
bcif_sw_2:
  lda $00, x
  and #$80
  bne bcif_sw_3
  jmp bcif_sw_1
bcif_sw_3:
  txa
  cmp BKP
  beq bcif_sw_4
  jmp bcif_w
bcif_sw_4:
  ldx SQR
bcif_sw_5:
  txa
  clc
  adc #$11
  tax
  and #$88
  beq bcif_sw_6
  jmp bcif_end
bcif_sw_6:
  lda $00, x
  and #$80
  bne bcif_sw_7
  jmp bcif_sw_5
bcif_sw_7:
  lda $00, x
  and #%11000010
  cmp #%10000010
  bne bcif_sw_8
  lda #%00100000
  sta PIN
bcif_sw_8:
  jmp bcif_end

bcif_w:
  ldx SQR
bcif_w_1:
  txa
  sec
  sbc #$01
  tax
  bcc bcif_w_3
  and #$88
  beq bcif_w_2
  jmp bcif_end
bcif_w_2:
  lda $00, x
  and #$80
  bne bcif_w_3
  jmp bcif_w_1
bcif_w_3:
  txa
  cmp BKP
  beq bcif_w_4
  jmp bcif_end
bcif_w_4:
  ldx SQR
bcif_w_5:
  txa
  clc
  adc #$01
  tax
  and #$88
  beq bcif_w_6
  jmp bcif_end
bcif_w_6:
  lda $00, x
  and #$80
  bne bcif_w_7
  jmp bcif_w_5
bcif_w_7:
  lda $00, x
  and #%11000100
  cmp #%10000100
  bne bcif_w_8
  lda #%00010000
  sta PIN
bcif_w_8:
  jmp bcif_end

bcif_end:
  rts

;**********************************************************
;**********************************************************
;**********************************************************


boption_ki_cstl:
  lda BCA
  bne boption_ki_cstl_1
  jmp boption_ki_cstl_e
; checks if a castle is possible (BCA /= 0x00)

boption_ki_cstl_1:
  lda BCA
  and #%11110000
  beq boption_ki_cstl_2
  jsr boption_ki_cstl_l
; left side castle possible? (4 high bits of BCA)

boption_ki_cstl_2:
  lda BCA
  and #%00001111
  beq boption_ki_cstl_e
  jsr boption_ki_cstl_r 
; right side castle possible? (4 low bits of BCA)
boption_ki_cstl_e:
  rts

;**********************************************************

boption_ki_cstl_l:
boption_ki_cstl_l_1:
  lda %01110001
  and #%10000000
  beq boption_ki_cstl_l_2
  jmp boption_ki_cstl_l_e
boption_ki_cstl_l_2:
  lda %01110010
  and #%10000000
  beq boption_ki_cstl_l_2b
  jmp boption_ki_cstl_l_e
boption_ki_cstl_l_2b:
  lda #%01110010
  sta SQR
  jsr bchecka
  lda PIN
  beq boption_ki_cstl_l_3
  jmp boption_ki_cstl_l_e
boption_ki_cstl_l_3:
  lda %01110011
  and #%10000000
  beq boption_ki_cstl_l_3b
  jmp boption_ki_cstl_l_e
boption_ki_cstl_l_3b:
  lda #%01110011
  sta SQR
  jsr bchecka
  lda PIN
  beq boption_ki_cstl_l_hit
  jmp boption_ki_cstl_l_e
boption_ki_cstl_l_hit:
  ldy OTP
  lda #$72
  iny
  sta $00, y
  sta CSTLL
  sty OTP
boption_ki_cstl_l_e:
  rts

;**********************************************************

boption_ki_cstl_r:
boption_ki_cstl_r_2:
  lda $75
  and #$80
  beq boption_ki_cstl_r_2b
  jmp boption_ki_cstl_r_e
boption_ki_cstl_r_2b:
  lda #$75
  sta SQR
  jsr bchecka
  lda PIN
  beq boption_ki_cstl_r_3
  jmp boption_ki_cstl_r_e
boption_ki_cstl_r_3:
  lda $76
  and #$80
  beq boption_ki_cstl_r_3b
  jmp boption_ki_cstl_r_e
boption_ki_cstl_r_3b:
  lda #$76
  sta SQR
  jsr bchecka
  lda PIN
  beq boption_ki_cstl_r_hit
  jmp boption_ki_cstl_r_e
boption_ki_cstl_r_hit:
  ldy OTP
  lda #$76
  iny
  sta $00, y
  sta CSTLR
  sty OTP
boption_ki_cstl_r_e:
  rts

;**********************************************************

bchecka_bi:
bchecka_bi_ne:
  lda SQR
bchecka_bi_ne_1:
  clc
  adc #$11
  tax
  and #$88
  bne bchecka_bi_nw
  lda $00, x
  and #$80
  bne bchecka_bi_ne_2
  txa
  jmp bchecka_bi_ne_1
bchecka_bi_ne_2:
  lda $00, x
  and #%11000010
  cmp #%10000010
  bne bchecka_bi_nw
  jmp bchecka_bi_hit

bchecka_bi_nw:
  lda SQR
bchecka_bi_nw_1:
  clc
  adc #$0f
  tax
  and #$88
  bne bchecka_bi_se
  lda $00, x
  and #$80
  bne bchecka_bi_nw_2
  txa
  jmp bchecka_bi_nw_1
bchecka_bi_nw_2:
  lda $00, x
  and #%11000010
  cmp #%10000010
  bne bchecka_bi_se
  jmp bchecka_bi_hit

bchecka_bi_se:
  lda SQR
bchecka_bi_se_1:
  sec
  sbc #$0f
  bcc bchecka_bi_sw
  tax
  and #$88
  bne bchecka_bi_sw
  lda $00, x
  and #$80
  bne bchecka_bi_se_2
  txa
  jmp bchecka_bi_se_1
bchecka_bi_se_2:
  lda $00, x
  and #%11000010
  cmp #%10000010
  bne bchecka_bi_sw
  jmp bchecka_bi_hit

bchecka_bi_sw:
  lda SQR
bchecka_bi_sw_1:
  sec
  sbc #$11
  bcc bchecka_bi_e
  tax
  and #$88
  bne bchecka_bi_e
  lda $00, x
  and #$80
  bne bchecka_bi_sw_2
  txa
  jmp bchecka_bi_sw_1
bchecka_bi_sw_2:
  lda $00, x
  and #%11000010
  cmp #%10000010
  bne bchecka_bi_e
  jmp bchecka_bi_hit
bchecka_bi_hit:
  lda #$ff
  sta PIN
bchecka_bi_e:
  rts

;**********************************************************

bchecka_ro:
bchecka_ro_n:
  lda SQR
bchecka_ro_n_1:
  clc
  adc #$10
  tax
  and #$88
  bne bchecka_ro_e
  lda $00, x
  and #$80
  bne bchecka_ro_n_2
  txa
  jmp bchecka_ro_n_1
bchecka_ro_n_2:
  lda $00, x
  and #%11000100
  cmp #%10000100
  bne bchecka_ro_e
  jmp bchecka_ro_hit

bchecka_ro_e:
  lda SQR
bchecka_ro_e_1:
  clc
  adc #$01
  tax
  and #$88
  bne bchecka_ro_s
  lda $00, x
  and #$80
  bne bchecka_ro_e_2
  txa
  jmp bchecka_ro_e_1
bchecka_ro_e_2:
  lda $00, x
  and #%11000100
  cmp #%10000100
  bne bchecka_ro_s
  jmp bchecka_ro_hit

bchecka_ro_s:
  lda SQR
bchecka_ro_s_1:
  sec
  sbc #$10
  bcc bchecka_ro_w
  tax
  and #$88
  bne bchecka_ro_w
  lda $00, x
  and #$80
  bne bchecka_ro_s_2
  txa
  jmp bchecka_ro_s_1
bchecka_ro_s_2:
  lda $00, x
  and #%11000100
  cmp #%10000100
  bne bchecka_ro_w
  jmp bchecka_ro_hit

bchecka_ro_w:
  lda SQR
bchecka_ro_w_1:
  sec
  sbc #$01
  bcc bchecka_ro_end
  tax
  and #$88
  bne bchecka_ro_end
  lda $00, x
  and #$80
  bne bchecka_ro_w_2
  txa
  jmp bchecka_ro_w_1
bchecka_ro_w_2:
  lda $00, x
  and #%11000100
  cmp #%10000100
  bne bchecka_ro_end
  jmp bchecka_ro_hit
bchecka_ro_hit:
  lda #$ff
  sta PIN
bchecka_ro_end:
  rts

;**********************************************************
;**********************************************************
;**********************************************************

w_piece_option:
  lda SQC
  sta SQR
  jsr wcif

  lda PIN
  bne w_piece_option1
  jsr w_piece_pop0
  jmp w_piece_optione

w_piece_option1:
  lda PIN
  cmp #%10000000
  bne w_piece_option2
  jsr w_piece_pop1
  jmp w_piece_optione

w_piece_option2:
  lda PIN
  cmp #%01000000
  bne w_piece_option3
  jsr w_piece_pop2
  jmp w_piece_optione

w_piece_option3:
  lda PIN
  cmp #%00100000
  bne w_piece_option4
  jsr w_piece_pop3
  jmp w_piece_optione

w_piece_option4:
  lda PIN
  cmp #%00010000
  bne w_piece_optione
  jsr w_piece_pop4
  jmp w_piece_optione
	
w_piece_optione:
  rts

;**********************************************************


b_piece_option:
  lda SQC
  sta SQR
  jsr bcif

  lda PIN
  bne b_piece_option1
  jsr b_piece_pop0
  jmp b_piece_optione

b_piece_option1:
  lda PIN
  cmp #%10000000
  bne b_piece_option2
  jsr b_piece_pop1
  jmp b_piece_optione

b_piece_option2:
  lda PIN
  cmp #%01000000
  bne b_piece_option3
  jsr b_piece_pop2
  jmp b_piece_optione

b_piece_option3:
  lda PIN
  cmp #%00100000
  bne b_piece_option4
  jsr b_piece_pop3
  jmp b_piece_optione

b_piece_option4:
  lda PIN
  cmp #%00010000
  bne b_piece_optione
  jsr b_piece_pop4
  jmp b_piece_optione
	
b_piece_optione:
  rts


;**********************************************************
;**********************************************************
;**********************************************************

wmove:
  jsr option_clear
  jsr block_clear

  ldx SQO
  lda $00, x
  and #%11001111
  cmp #%10000000
  bne wmove1 ; if not pawn move to next item
  lda SQF
  and #%11110000
  cmp #%01110000
  bne wmove1 ; if not on last rank move to next item

  jsr wpromo

  lda PROM
  ldx SQF
  sta $00, x

  lda #$00
  ldx SQO
  sta $00, x

  jmp wmove_end
wmove1:
; checks if an en passant sequence should be set
  lda SQF
  cmp ENS
  bne wmove2
  lda SQF
  tax
  sta WENA
  txa
  sec
  sbc #$10
  sta WENB
  jmp wmove_typ

wmove2:
; checks if an en passant squence should occur
  lda SQF
  cmp ENP
  bne wmove3

  lda #wp
  ldx BENB
  sta $00, x

  lda #$00
  ldx BENA
  sta $00, x

  ldx SQO
  sta $00, x
  
  jmp wmove_end

wmove3:
   
  lda SQF
  cmp CSTLL
  bne wmove4

  ldx #$02
  stx WKP

  lda #wk
  sta $02
  lda #wr
  sta $03

  lda #$00
  sta $00
  sta $04

  lda #$00
  sta WCA
  jmp wmove_end

wmove4:
   
  lda SQF
  cmp CSTLR
  bne wmove5

  ldx #$06
  stx WKP

  lda #wk
  sta $06
  lda #wr
  sta $05

  lda #$00
  sta $07
  sta $04

  lda #$00
  sta WCA
  jmp wmove_end

wmove5:

  ldx SQO
  lda $00, x
  and #%11001111
  cmp #wr
  beq wmove5_1
  jmp wmove6
wmove5_1:
  txa
  cmp #$00
  bne wmove6
  lda WCA
  and #%00001111
  sta WCA
  jmp wmove_typ	

wmove6:

  ldx SQO
  lda $00, x
  and #%11001111
  cmp #wr
  beq wmove6_1
  jmp wmove7
wmove6_1:
  txa
  cmp #$07
  bne wmove7
  lda WCA
  and #%11110000
  sta WCA
  jmp wmove_typ

wmove7:

  ldx SQO
  txa
  cmp WKP
  bne wmove_typ
  lda SQF
  sta WKP
  lda #$00
  sta WCA
  jmp wmove_typ

wmove_typ:
  ldx SQO
  lda $00, x
  ldx SQF
  sta $00, x
  
  lda #$00
  ldx SQO
  sta $00, x

wmove_end:
  jsr update_board_white
  rts

;**********************************************************
;**********************************************************
;**********************************************************


bmove:
  jsr option_clear
  jsr block_clear

  ldx SQO
  lda $00, x
  and #%11001111
  cmp #%11000000
  bne bmove1 ; if not pawn move to next item
  lda SQF
  and #%11110000
  cmp #%00000000
  bne bmove1 ; if not on last rank move to next item

  jsr bpromo

  lda PROM
  ldx SQF
  sta $00, x

  lda #$00
  ldx SQO
  sta $00, x

  jmp bmove_end
bmove1:

  lda SQF
  cmp ENS
  bne bmove2
  lda SQF
  sta BENA
  clc
  adc #$10
  sta BENB
  jmp bmove_typ

bmove2:
  
  lda SQF
  cmp ENP
  bne bmove3

  lda #bp
  ldx WENB
  sta $00, x

  lda #$00
  ldx WENA
  sta $00, x

  ldx SQO
  sta $00, x
  
  jmp bmove_end

bmove3:
   
  lda SQF
  cmp CSTLL
  bne bmove4

  ldx #$72
  stx BKP

  lda #bk
  sta $72
  lda #br
  sta $73

  lda #$00
  sta $70
  sta $74

  lda #$00
  sta BCA
  jmp bmove_end

bmove4:
   
  lda SQF
  cmp CSTLR
  bne bmove5

  ldx #$76
  stx BKP

  lda #bk
  sta $76
  lda #br
  sta $75

  lda #$00
  sta $77
  sta $74

  lda #$00
  sta BCA
  jmp bmove_end

bmove5:

  ldx SQO
  lda $00, x
  and #%11001111
  cmp #br
  beq bmove5_1
  jmp bmove6
bmove5_1:
  txa
  cmp #$70
  bne bmove6
  lda BCA
  and #%00001111
  sta BCA
  jmp bmove_typ	

bmove6:

  ldx SQO
  lda $00, x
  and #%11001111
  cmp #br
  beq bmove6_1
  jmp bmove7
bmove6_1:
  txa
  cmp #$77
  bne bmove7
  lda BCA
  and #%11110000
  sta BCA
  jmp bmove_typ

bmove7:

  ldx SQO
  txa
  cmp BKP
  bne bmove_typ
  lda SQF
  sta BKP
  lda #$00
  sta BCA
  jmp bmove_typ

bmove_typ:
  ldx SQO
  lda $00, x
  ldx SQF
  sta $00, x
  
  lda #$00
  ldx SQO
  sta $00, x

bmove_end:
  jsr update_board_black
  rts


;**********************************************************
;**********************************************************
;**********************************************************


wreset_tickers:
  lda #$ff
  sta WENA
  sta WENB
  sta ENP
  sta ENS
  sta PROM
  sta CSTLR
  sta CSTLL
  lda #$e0
  sta OTP
  rts

breset_tickers:
  lda #$ff
  sta BENA
  sta BENB
  sta ENP
  sta ENS
  sta PROM
  sta CSTLR
  sta CSTLL
  lda #$e0
  sta OTP
  rts


;**********************************************************

option_to_board:
  ldy OTP
option_to_board_1:
  tya
  cmp #%11100000
  beq option_to_board_e
  lda $00, y
  tax
  lda $00, x
  ora #%00100000
  sta $00, x
  dey
  jmp option_to_board_1
option_to_board_e:
  rts

;**********************************************************

option_clear: ; use with a board update
  lda #$e0
  sta OTP
  ldx #$80
option_clear_1:
  dex
  txa
  and #%10001000
  bne option_clear_1
  lda $00, x
  and #%11011111
  sta $00, x
  txa
  cmp #$00
  bne option_clear_1
option_clear_e:
  rts

;**********************************************************

specialoption:
  ldx #$80
  jsr option_clear_1
  ldx #$80
  jsr block_clear_1

  lda SQC
  cmp BKP
  beq specialoption_1

  lda SQC
  cmp WKP
  beq specialoption_1

  jmp specialoption_2

specialoption_1:
  jsr option_to_board
  jmp specialoption_e

specialoption_2:
  jsr block_to_board
  jsr pawn_special
  jsr blockoption_to_board
  jmp specialoption_e

specialoption_e:
  rts

pawn_special:
  ldx SQC
  lda $00, x
  cmp #wp
  bne pawn_special_1

  lda BENB
  cmp #$ff
  beq pawn_special_1

  ldx BENB
  lda $00, x
  ora #%00010000
  sta $00, x
  jmp pawn_special_end


pawn_special_1:
  ldx SQC
  lda $00, x
  cmp #bp
  bne pawn_special_end

  lda WENB
  cmp #$ff
  beq pawn_special_end

  ldx WENB
  lda $00, x
  ora #%00010000
  sta $00, x
  jmp pawn_special_end


pawn_special_end:
  rts
;**********************************************************



blockoption_to_board:
  ldy OTP
blockoption_to_board_1:
  tya
  cmp #%11100000
  beq blockoption_to_board_e
  lda $00, y
  tax
  lda $00, x

  and #%00010000
  beq blockoption_to_board_2

  lda $00, x
  ora #%00100000
  sta $00, x

blockoption_to_board_2:

  dey
  jmp blockoption_to_board_1

blockoption_to_board_e:
  rts

;**********************************************************

block_to_board:
  ldy BSP
block_to_board_1:
  tya
  cmp #$d0
  beq block_to_board_e
  lda $00, y
  tax
  lda $00, x
  ora #%00010000
  sta $00, x
  dey
  jmp block_to_board_1
block_to_board_e:
  rts

;**********************************************************

block_clear: ; use with a board update
  lda #$c0
  sta BSP
  ldx #$80
block_clear_1:
  dex
  txa
  and #%10001000
  bne block_clear_1
  lda $00, x
  and #%11101111
  sta $00, x
  txa
  cmp #$00
  bne block_clear_1
block_clear_e:
  rts

;**********************************************************

update_board_white:
  ldx #$80
update_board_white_1:
  dex
  txa
  and #%10001000
  bne update_board_white_1
  txa
  sta SSP
  lda $00, x
  sta SSV
  jsr update
  txa
  cmp #%00000000
  bne update_board_white_1

  rts

;**********************************************************

update_board_black:
  ldx #$80
update_board_black_1:
  dex
  txa
  and #%10001000
  bne update_board_black_1
  txa
  eor #%01110111
  sta SSP
  lda $00, x
  sta SSV
  jsr update
  txa
  cmp #%00000000
  bne update_board_black_1
  rts

;**********************************************************

load_white:
  lda #L
  sta PORTA
  lda #%00000000
  sta DDRB
  jsr wait_3
  lda PORTB
  sta SQC
  lda #0
  sta PORTA
  jsr wait_4
  lda #%11111111
  sta DDRB
  lda #0
  sta PORTA
  rts

;**********************************************************

load_black:
  lda #L
  sta PORTA
  lda #%00000000
  sta DDRB
  jsr wait_3
  lda PORTB
  eor #%01110111
  sta SQC
  lda #0
  sta PORTA
  jsr wait_4
  lda #%11111111
  sta DDRB
  lda #0
  sta PORTA
  rts

;**********************************************************

white_ckmg:
  lda #%10001111
  ldx WKP
  sta $00, x
  sta SSV
  lda WKP
  eor #%01110111
  sta SSP
  jsr update
  rts

;**********************************************************

black_ckmg:
  lda #%11001111
  ldx BKP
  sta $00, x
  sta SSV
  lda BKP
  sta SSP
  jsr update
  rts

;**********************************************************

wpromo:
  jsr white_promotion_ask
wpromo_1:
  jsr load_white
  lda SQC
  tax
  and #%11111000
  cmp #%00001000
  bne wpromo_1

wpromo_q:
  txa
  cmp #$08
  bne wpromo_r
  lda #wq
  sta PROM
  jmp wpromo_end

wpromo_r:
  txa
  cmp #$09
  bne wpromo_b
  lda #wr
  sta PROM
  jmp wpromo_end

wpromo_b:
  txa 
  cmp #$0a
  bne wpromo_n
  lda #wb
  sta PROM
  jmp wpromo_end

wpromo_n:
  lda #wn
  sta PROM
  jmp wpromo_end

wpromo_end:
  lda #$00
  sta SSV
  lda #$08
  sta SSP
  jsr update

  lda #$00
  sta SSV
  lda #$09
  sta SSP
  jsr update

  lda #$00
  sta SSV
  lda #$0a
  sta SSP
  jsr update

  lda #$00
  sta SSV
  lda #$0b
  sta SSP
  jsr update
  rts

;**********************************************************

bpromo:
  jsr black_promotion_ask
bpromo_1:
  jsr load_white
  lda SQC
  tax
  and #%11111000
  cmp #%00001000
  bne bpromo_1

bpromo_q:
  txa
  cmp #$08
  bne bpromo_r
  lda #bq
  sta PROM
  jmp bpromo_end

bpromo_r:
  txa
  cmp #$09
  bne bpromo_b
  lda #br
  sta PROM
  jmp bpromo_end

bpromo_b:
  txa 
  cmp #$0a
  bne bpromo_n
  lda #bb
  sta PROM
  jmp bpromo_end

bpromo_n:
  lda #bn
  sta PROM
  jmp bpromo_end

bpromo_end:
  lda #$00
  sta SSV
  lda #$08
  sta SSP
  jsr update

  lda #$00
  sta SSV
  lda #$09
  sta SSP
  jsr update

  lda #$00
  sta SSV
  lda #$0a
  sta SSP
  jsr update

  lda #$00
  sta SSV
  lda #$0b
  sta SSP
  jsr update
  rts

;**********************************************************

white_promotion_ask:
  lda #wq
  sta SSV
  lda #$08
  sta SSP
  jsr update

  lda #wr
  sta SSV
  lda #$09
  sta SSP
  jsr update

  lda #wb
  sta SSV
  lda #$0a
  sta SSP
  jsr update

  lda #wn
  sta SSV
  lda #$0b
  sta SSP
  jsr update

  rts

black_promotion_ask:
  lda #bq
  sta SSV
  lda #$08
  sta SSP
  jsr update

  lda #br
  sta SSV
  lda #$09
  sta SSP
  jsr update

  lda #bb
  sta SSV
  lda #$0a
  sta SSP
  jsr update

  lda #bn
  sta SSV
  lda #$0b
  sta SSP
  jsr update

  rts

delay:
  lda #$ff
  sta SSP
  lda #$ff
  sta SSV
  jsr update
  jsr load_white
  rts

update:
  lda SSP
  sta PORTB
  jsr send

  lda SSV
  sta PORTB
  jsr send

  rts

send:
  lda #S
  sta PORTA
  jsr wait_1
  lda #$00
  sta PORTA
  jsr wait_2
  lda #0
  sta PORTA
  rts

wait_1:
  lda #%00000000
  sta DDRA
busy_1:
  lda PORTA
  and #RDY
  beq busy_1
  lda #%00001001
  sta DDRA
  rts

wait_2:
  lda #%00000000
  sta DDRA
busy_2:
  lda PORTA
  and #RDY
  bne busy_2
  lda #%00001001
  sta DDRA
  rts

wait_3:
  lda #%00000000
  sta DDRA
busy_3:
  lda PORTA
  and #RDX
  beq busy_3
  lda #%00001001
  sta DDRA
  rts

wait_4:
  lda #%00000000
  sta DDRA
busy_4:
  lda PORTA
  and #RDX
  bne busy_4
  lda #%00001001
  sta DDRA
  rts

load_board:
  lda #%10000100
  sta $00
  sta $07

  lda #%10000001
  sta $01
  sta $06

  lda #%10000010
  sta $02
  sta $05

  lda #%10000110
  sta $03

  lda #%10001000
  sta $04
  lda #$04
  sta WKP

  lda #%10000000
  sta $10
  sta $11
  sta $12
  sta $13
  sta $14
  sta $15
  sta $16
  sta $17

  lda #%11000100
  sta $70
  sta $77

  lda #%11000001
  sta $71
  sta $76

  lda #%11000010
  sta $72
  sta $75

  lda #%11000110
  sta $73

  lda #%11001000
  sta $74
  lda #$74
  sta BKP

  lda #%11000000
  sta $60
  sta $61
  sta $62
  sta $63
  sta $64
  sta $65
  sta $66
  sta $67

  lda #%00000000
  sta $20
  sta $21
  sta $22
  sta $23
  sta $24
  sta $25
  sta $26
  sta $27

  sta $30
  sta $31
  sta $32
  sta $33
  sta $34
  sta $35
  sta $36
  sta $37

  sta $40
  sta $41
  sta $42
  sta $43
  sta $44
  sta $45
  sta $46
  sta $47

  sta $50
  sta $51
  sta $52
  sta $53
  sta $54
  sta $55
  sta $56
  sta $57
  
  lda #$ff
  sta WCA
  sta BCA

  lda #%11100000
  sta OTP

  lda #%11000000
  sta BSP

  lda #%10100000
  sta KMP

  lda #%10110000
  sta BPP

  lda #$ff
  sta WENA
  sta WENB
  sta BENA
  sta BENB
  sta CSTLR
  sta CSTLL
  sta ENP
  sta PROM
  sta ENS

  rts

nmib:
  rti

  .segment "VECTORS"
  .word nmib
  .word reset
  .word $0000









