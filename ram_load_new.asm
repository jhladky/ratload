; CPE233 FINAL PROJECT
; JACOB HLADKY
.EQU SERIAL_IN = 0x0F
.EQU SERIAL_OUT	= 0x0E
.EQU SSEG_OUT = 0x81

.DSEG
.ORG 0x00

.CSEG 
.ORG 0x01

; We are going to use R30, R31 as scratch (useless)
; registers. R0 will store the serial byte
; R16 will be used for the WSP ins: thus it MUST ALWAYS be 0x00
; this program will BLINDLY LOOP through the following sequence:
; 1. get a byte 1 from serial in
; 2. call special command LDSP (really an OUT, we just want
; to get the byte on the tristate)
; 3. also send the data out to the sseg to show it's transmitting
; the interrupt signals the serial data is ready

init:
SEI           ; we want interrupts lol
MOV R1, 0x7E  ; move the confirm signal into a register
OUT R1, SERIAL_OUT
MOV R16, 0x00 ; the register used for the last WSP ins
BRN loop      ; go to the loop, wait for the interrupt

loop:         ; now we wait
MOV R30, R31 
BRN loop

isr:
IN R0, SERIAL_IN
; this is the interceptor command [LDPR]
; has to be an out in the asm file, 
; in the prog_rom it's manually changed
OUT R0, SERIAL_OUT
OUT R0, SSEG_OUT
RETIE

.ORG 0x3FF
BRN isr;
