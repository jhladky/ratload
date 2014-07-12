1/ SUMMARY
The goal of this project was to enable loading of a new assembly program onto the RAT CPU without the need for re synthesis. In that end, the project was successful. In theory this project could make it significantly easier to test assembly programs, as lengthly synthesis and routing times are avoided. However its practical use is limited by number of factors, described in Section 4. The other sections describe, respectively, what each part of the project does and how to use the project to load your own assembly code. 

2/ DESCRIPTION OF PROJECT
i) The RATLoad program
a. Dependencies and Compilation
The RATLoad program is written in C++ and should work on any POSIX compliant OS. It was tested and used on an up-to-date x64 Gentoo Linux system. RATLoad uses the libSerial libraries, so those are necessary for compilation and operation. There are no other dependencies. The following compile command is suggested: 
g++ -O2 -lserial -o RATLoad [path to RATLoad.cpp].
The program also requires that the serial port support the following options: software flow control, 8-bit words with 1 stop-bit and odd parity, 9600 baud.
      
b. Arguments and Operation
The program needs two arguments: the location of the prog_rom.vhd file and the location of the serial device used to communicate with the RAT CPU. These are designated as -f and -d, respectively. For example, using RATLoad on a linux system with the prog_rom file in the same directory as the program looks like this: 
example ~ # ./RATLoad -d /dev/ttyUSB0 -f prog_rom.vhd. 
Please note that the program needs to be run as root in order to access the serial device. When the program is run, it will open the prog_rom.vhd file read only, parse the INIT and INITP arrays, and the communicate with the RAT CPU to send the array to the new RAM. 
      
c. Possible Errors
In addition to the standard file I/O errors, a number of issues are possible with configuration of the serial device. As previously mentioned, if the program is not run as root, it will probably fail with 'Attempt to open serial device failed'. Additionally, if the serial port does not support any of the necessary options, the program will fail with 'Serial Configuration Failed'. Because this program is fairly simple, and I am fairly lazy, no error checking is done in either the UART or the program, so if data is corrupted during transmission, the program may hang at 'Connection Opened: Sending Data'. In this case the board should be reprogrammed and the program rerun. 

ii) The UART
Digilent provided a UART module that interfaced with the serial port on the board, but a state machine had to be written to convert the chars going into the board to integers the CPU can understand (and the reverse, obviously), and to control the flow of data through the UART. This sate machine was based on an example provided by Digilent, but expanded to work with the requirements of the project. The UART state machine waits for a conformation byte (an ACSII ~, chosen at random), when the byte is received, it then sends this byte (the ~) back. This two-step process is required to initiate transmission between the two devices. It should be noted that this is a very simple, not complete, and non-standard handshaking process. But for this application it is sufficient. When the program receives the start byte, transmission of the prog_rom.vhd file starts, and the following process is repeated: 
1. The computer sends a byte from the prog_rom.vhd file (specifically, it sends one hex character from the INIT or INITP arrays) 
2. When the UART receives the byte, it converts it to an integer and sends an interrupt out to the RAT CPU. 
3. The UART then waits for the CPU to send the byte to the CPU's out-port, indicating the byte has been received and processed
4. When this condition occurs, the UART converts the bike back into a char and sends it back to the program. When the program receives the byte back, the process repeats. 
   
iii) The New Prog Rom Module
The old prog rom module was simply a wrapper for a Xilinx provided RAM. The new prog rom makes one major change to the external top-level of the old prog rom, and several changes to its internals. On the top-level, the new prog rom (referred to from now on simply as 'the prog rom') adds an 8-bit in-port for the tristate bus. This is to enable data from the serial port to come into the prog ram. Internally, the prog rom contains the old prog rom, another -- writeable -- ram, and an 'interceptor' module. The new RAM is simply another Xilinx provided module, so it is of little interest. The interceptor is where the magic happens. This module is a state machine with the following behavior:
1.Wait for a special instruction to be sent from the old prog rom, the LDPR instruction. This instruction indicates that a byte of data has been recieved from the serial port, and that it is part of the new prog ram.
2. When it receives this special instruction, it replaces it with an out (something the control unit understands), and stores it. 
3. When 5 LDPR instructions have been intercepted, an instruction has been sent. The interceptor then writes this instruction to the prog ram and waits for the next LDPR instruction
4. When 1024 instructions have been sent (5120 LDPR commands), the interceptor sends out a BRN instruction to reset the program counter to 0, and a WSP instruction to reset the stack pointer to 0, and forcibly transfers control of the CPU to the new prog ram.
5. At this point the new program is loaded and running, and the interceptor remains in this end state until reprogrammed. 

iv) Summary
These three components work together to load a new program onto the CPU without need for resynthesis. Each part is dependent on the others, and relies on very exact behavior patterns being followed, nearly all of which are non standardized. However testing has shown that this configuration is stable. Basically, after initial bugs were resolved, I was not able to make the RATLoad components behave incorrectly, even with complicated programs using various I/O devices. Although it's use is limited (See section 4), RATLoad is nonetheless a capable and robust project.

3/ OPERATION OF PROJECT
Load the rat_wrapper.bit bit file onto the Nexys2. Then connect the Nexys2 to your computer with a male-to-female or USB-to-female serial cable. Start the RATLoad program, supplying the proper arguments to the flags described in section 2i. The RATLoad program will display "Finished!" when the program has been loaded onto the board. After this, the serial cable may be disconnected and the board used as if it had been programmed with the loaded prog_rom file. 

4/ FUTURE IMPROVEMENTS
Although, as mentioned, my original goals for this project were met, my vision of a dynamic CPU has not been met, due to 3 limitations:
i) The serial port: no one has a serial cable anymore. Although the serial interface is simple(r) than a USB, it is infinitely more annoying to require two separate cables, one for power, and one for data, when one could easily suffice (especially when that one is already programming the initial bit file). If I had another two weeks, I would attempt to use the USB interface for data transmission:

ii) Interrupts: Currently the RAT CPU only takes one interrupt, which is being used by the UART, thus most (useful) peripherals like the mouse and keyboard cannot be used. In the future I would add a mux for interrupts so RATLoad could be used more easily with advanced projects.

iii) The constants for I/O vary project to project. In the future I would add an interface allowing different 'constants' to be programmed in at 'boot' (pre-load) time.

The RATLoad opens up a world of possibilities for the RAT CPU, some of which I intend to pursue. In my eyes, this program has transformed the RAT CPU from a static, primarily pedagogical tool, to a dynamic, practical (to a point) processor that can be expanded and improved. Future projects, such as a real bios (allowing finer control of I/0), an expanded prog rom (allowing for >1024 line programs), and something resembling a RAT assembly read-evaluate-print-loop seem not only possible, but within reach. 
