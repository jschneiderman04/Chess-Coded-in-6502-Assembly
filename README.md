The main file "assemblychess.s" should be compiled into an object file. I recommend the ca65 compiler. Then the object file can be converted to a binary file using the linker.
Use this binary file and program it into the EEPROM of the breadboard computer.
The layout for the breadboard computer is based on the ben eater design, I recommend checking his stuff out
For the handshake between the breadboard computer and the graphics emulator (I used my macbook, anything that can run python with a usb port should work) I used an Arduino Mega with the provided C++ code

Thank you,
Jacob
