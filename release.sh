#!/bin/bash

# This script should be run on a machine that can compile latex files and the POSIX version of the ratload program

PRJ_DIR="project_master_v`cat .version`"

if [ -e $PRJ_DIR ]; then
    rm -rf $PRJ_DIR
fi

if [ ! -e "doc/README.pdf" ]; then
    cd doc
    ./latex.sh
    cd ..
fi

if [ ! -e "bin/ratload_Linux_x86_64" ]; then
    cd nix
    make clean && make
    cd ..
fi

mkdir $PRJ_DIR
mkdir $PRJ_DIR/bin
mkdir $PRJ_DIR/bin/ratload_Windows/
mkdir $PRJ_DIR/vhdl

cp RAT_CPU/uart.vhd $PRJ_DIR/vhdl/
cp RAT_CPU/RS232RefComp.vhd $PRJ_DIR/vhdl/
cp RAT_CPU/ascii_to_int.vhd $PRJ_DIR/vhdl/
cp RAT_CPU/int_to_ascii.vhd $PRJ_DIR/vhdl/
cp RAT_CPU/interceptor.vhd $PRJ_DIR/vhdl/
cp RAT_CPU/prog_rom.vhd $PRJ_DIR/vhdl/
cp RAT_CPU/prog_ram.vhd $PRJ_DIR/vhdl/
cp RAT_CPU/real_prog_rom.vhd $PRJ_DIR/vhdl/
cp SERIAL_TEST/prog_rom.vhd $PRJ_DIR/vhdl/serial_test.vhd

cp doc/README.pdf $PRJ_DIR

cp bin/ratload_Linux_x86_64 $PRJ_DIR/bin/
cp bin/ratload_Windows_x86.exe $PRJ_DIR/bin/ratload_Windows/

cp win/app.py $PRJ_DIR/bin/ratload_Windows/
cp win/ratload_logo.png $PRJ_DIR/bin/ratload_Windows/
