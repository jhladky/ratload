# Makefile for ratload development

DEPS=jssc.o
CLASSPATH="jssc.jar;."
CC=gcj
CCFLAGS=-static-libgcj -static-libgcc -Os -fjni

ratload.exe: Ratload.java $(DEPS)
	$(CC) $(CCFLAGS) --main=Ratload -o $@ -classpath $(CLASSPATH) $< $(DEPS)

%.o: %.jar
	$(CC) $(CCFLAGS) -c $< -o $@

clean:
	@rm -f ratload.exe *.o
