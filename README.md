### SUMMARY
* Enables loading of a new assembly program onto the RAT CPU without the need for re-synthesis.
* Avoids lengthly synthesis times.
* Practical use is limited by a number of factors (Section 4).

### DESCRIPTION
#### RATLoad program
* Should work on any POSIX compliant system. `make` works for building.
* Requires that the serial port support software flow control, 8-bit words with 1 stop-bit and odd parity, and 9600 at least baud.
* Two arguments: the location of the prog_rom.vhd file and the location of the serial device used to communicate with the RAT CPU. These are designated as -f and -d, respectively. For example:
```
./RATLoad -d /dev/ttyUSB0 -f prog_rom.vhd
```
* Needs to be run as root in order to access the serial device. The program will open the prog_rom.vhd file read only, parse the INIT and INITP arrays, and the communicate with the RAT CPU to send the array to the new RAM.
* No error checking is done in either the UART or the program, so if data is corrupted during transmission, the program may hang at 'Connection Opened: Sending Data'. In this case the board should be *reprogrammed* and the program rerun.

#### The UART
Digilent provided a UART module that interfaced with the serial port on the board, but a state machine had to be written to convert the chars going into the board to integers the CPU can understand (and the reverse), and to control the flow of data through the UART. This state machine was based on an example provided by Digilent, but expanded to work with the requirements of the project. The state machine waits for a conformation byte (an ACSII ~, chosen at random), when the byte is received, it then sends this byte (the ~) back. This two-step process is required to initiate transmission between the two devices. Note that this is a very simple, not complete, and non-standard handshaking process. When the program receives the start byte, transmission of the prog_rom.vhd file starts, and the following process is repeated:

1. The computer sends a byte from the prog_rom.vhd file (specifically, it sends one hex character from the INIT or INITP arrays)
2. When the UART receives the byte, it converts it to an integer and sends an interrupt out to the RAT CPU.
3. The UART then waits for the CPU to send the byte to the CPU's out-port, indicating the byte has been received and processed
4. When this condition occurs, the UART converts the bike back into a char and sends it back to the program. When the program receives the byte back, the process repeats.

#### The New Prog Rom Module
The old prog rom module was simply a wrapper for a Xilinx provided RAM. The new prog rom makes one major change to the external top-level of the old prog rom, and several changes to its internals. On the top-level, the new prog rom (referred to from now on simply as 'the prog rom') adds an 8-bit in-port for the tristate bus. This is to enable data from the serial port to come into the prog ram. Internally, the prog rom contains the old prog rom, another -- writeable -- ram, and an 'interceptor' module. The new RAM is simply another Xilinx provided module, so it is of little interest. The interceptor is where the magic happens. This module is a state machine with the following behavior:

1. Wait for a special instruction to be sent from the old prog rom, the LDPR instruction. This instruction indicates that a byte of data has been recieved from the serial port, and that it is part of the new prog ram.
2. When it receives this special instruction, it replaces it with an out (something the control unit understands), and stores it.
3. When 5 LDPR instructions have been intercepted, an instruction has been sent. The interceptor then writes this instruction to the prog ram and waits for the next LDPR instruction
4. When 1024 instructions have been sent (5120 LDPR commands), the interceptor sends out a BRN instruction to reset the program counter to 0, and a WSP instruction to reset the stack pointer to 0, and forcibly transfers control of the CPU to the new prog ram.
5. At this point the new program is loaded and running, and the interceptor remains in this end state until reprogrammed.

### OPERATION
1. Load the "rat_wrapper.bit" file onto the Nexys2.
2. Connect the Nexys2 to your computer with a male-to-female or USB-to-female serial cable.
3. Start the RATLoad program, supplying the proper arguments to the flags described in section 2i.
4. The RATLoad program will display "Finished!" when the program has been loaded onto the board.
5. Then The serial cable may be disconnected and the board used as if it had been programmed with the loaded prog_rom file.

### FUTURE IMPROVEMENTS
1. Use USB interface for data transmission.
2. Interrupts: Currently the RAT CPU only takes one interrupt, which is being used by the UART; peripherals like the mouse and keyboard cannot be used. Add a mux for interrupts so RATLoad can be used with advanced projects.
3. The constants for I/O vary project to project. Add an interface allowing different 'constants' to be programmed in at 'boot' (pre-load) time.
