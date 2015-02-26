# Makefile for Windows CLI version of the ratload program.
# 'gcj' must be in the PATH. Cygwin is required to *build*, but not to run.

CC=gcj
DEPS=jssc.o
CCFLAGS=-static-libgcj -static-libgcc -O3 -fjni
CLASSPATH="jssc.jar;."
BINNAME=ratload_Windows_x86.exe

$(BINNAME): Ratload.java $(DEPS)
	$(CC) $(CCFLAGS) --main=Ratload -o ../bin/$@ -classpath $(CLASSPATH) $< $(DEPS)

%.o: %.jar
	$(CC) $(CCFLAGS) -c $< -o $@

clean:
	@rm -f $(BINNAME) *.o
