# ratload can be build on three different platforms: Windows, OS X, and Linux.
# On all three this Makefile assumes that 'gcj' is in the PATH. On Windows,
# Cygwin is required to *build* ratload, but not to run it.

CC=gcj
DEPS=jssc.o
OS = $(shell uname -s)
PROC = $(shell uname -m)
SUFFIX = $(OS)_$(PROC)

ifeq ("$(OS)", "CYGWIN_NT-6.1")
	CCFLAGS=-static-libgcj -static-libgcc -O3 -fjni
	CLASSPATH="jssc.jar;."
	BINNAME=ratload_Windows_x86.exe
else
	CCFLAGS=-O3 -fjni
	CLASSPATH="jssc.jar:."
	BINNAME=ratload_$(SUFFIX)
endif

$(BINNAME): Ratload.java $(DEPS)
	$(CC) $(CCFLAGS) --main=Ratload -o $@ -classpath $(CLASSPATH) $< $(DEPS)

%.o: %.jar
	$(CC) $(CCFLAGS) -c $< -o $@

clean:
	@rm -f $(BINNAME) *.o
