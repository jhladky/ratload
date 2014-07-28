# Makefile for RATLoad

CC=gcc
CFLAGS=-O3 -Wall -Wextra -pedantic -std=c99

RATLoad: RATLoad.o
	$(CC) $(CFLAGS) -o $@ RATLoad.o

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm RATLoad *.o
