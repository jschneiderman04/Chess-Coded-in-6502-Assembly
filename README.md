The main file "assemblychess.s" should be compiled into an object file. I recommend the ca65 compiler. Then the object file can be converted to a binary file using the linker ld65 and the configure file, kpl.cfg
Use this binary file and program it into the EEPROM of the breadboard computer

The layout for the breadboard computer is based on the ben eater design, I recommend checking his stuff out at beneater.net

For the handshake between the breadboard computer and the graphics emulator (I used my macbook, anything that can run python with a usb port should work) I used an Arduino Mega with the provided C++ code

Attach PORTB of the 65c22 chip to pins 38, 40, 42, 44, 46, 48, 50, 52 of the Arduino Mega where pin 52 is the MSB
Attach the 4 least significant bits of PORTA of the 65c22 chip to pins 24, 26, 28, 30 of the Arduino Mega where pin 24 is the LSB

Make sure to update the python script to be specific to the correct USB port, use your terminal to determine this

Run the python script

Please feel free to reach out if you have any questions

Thank you,
Jacob
