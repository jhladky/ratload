# Makefile for winRATLoad development

DEPS=jssc.o
CLASSPATH="jssc.jar;."
CC=gcj
CCFLAGS=-static-libgcj -static-libgcc -Os -fjni

winRATLoad.exe: Main.java $(DEPS)
	$(CC) $(CCFLAGS) --main=Main -o winRATLoad.exe -classpath $(CLASSPATH) Main.java $(DEPS)

%.o: %.jar
	$(CC) $(CCFLAGS) -c $< -o $@

clean:
	@rm -f winRATLoad.exe *.o
