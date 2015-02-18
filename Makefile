# Makefile for ratload program

CC=gcc
CFLAGS=-O3 -Wall -Wextra -pedantic -D_BSD_SOURCE -std=c99

ratload: ratload.o
	$(CC) $(CFLAGS) -o $@ ratload.o

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f ratload *.o
