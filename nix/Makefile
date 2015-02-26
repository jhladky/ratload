# Makefile for POSIX-compliant CLI version of ratload

CFLAGS=-O3 -Wall -Wextra -pedantic -D_BSD_SOURCE -std=c99
OS = $(shell uname -s)
PROC = $(shell uname -m)
SUFFIX=$(OS)_$(PROC)

ratload_$(SUFFIX): ratload.o
	$(CC) $(CFLAGS) -o ../bin/$@ ratload.o

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f ../bin/ratload_$(SUFFIX) *.o
