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

if [ ! -e "nix/ratload" ]; then
    cd nix
    make clean && make
    cd ..
fi

mkdir $PRJ_DIR
mkdir $PRJ_DIR/asm
mkdir $PRJ_DIR/bin
mkdir $PRJ_DIR/vhdl

cp asm/ratload.asm $PRJ_DIR/asm/
cp asm/serial_test.asm $PRJ_DIR/asm/

cp RAT_CPU/RS232RefComp.vhd $PRJ_DIR/vhdl/
cp RAT_CPU/ascii_to_int.vhd $PRJ_DIR/vhdl/
cp RAT_CPU/interceptor.vhd $PRJ_DIR/vhdl/
cp RAT_CPU/prog_rom.vhd $PRJ_DIR/vhdl/
cp RAT_CPU/prog_ram.vhd $PRJ_DIR/vhdl/
cp RAT_CPU/real_prog_rom.vhd $PRJ_DIR/vhdl/
cp SERIAL_TEST/prog_rom.vhd $PRJ_DIR/vhdl/serial_test.vhd

cp doc/README.pdf $PRJ_DIR

cp nix/ratload $PRJ_DIR/bin/ratload_nix

cp win/winRATLoad.exe $PRJ_DIR/bin/ratload_win.exe
