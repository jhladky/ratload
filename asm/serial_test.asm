; CPE233 FINAL PROJECT
; JACOB HLADKY
.EQU SERIAL_IN = 0x0F
.EQU SERIAL_OUT	= 0x0E
.EQU LEDS_OUT = 0x40

.DSEG
.ORG 0x00

.CSEG 
.ORG 0x01

init:
SEI           ; we want interrupts lol
BRN loop      ; go to the loop, wait for the interrupt

loop:         ; now we wait
MOV R30, R31
BRN loop

isr:
IN R0, SERIAL_IN
OUT R0, LEDS_OUT
OUT R0, SERIAL_OUT
RETIE

.ORG 0x3FF
BRN isr;
