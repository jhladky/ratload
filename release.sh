#!/bin/bash

PRJ_DIR="project_master_v`cat .version`"

if [ -e $PRJ_DIR ]; then
    rm -rf $PRJ_DIR
fi

if [ ! -e "README.pdf" ]; then
    ./latex.sh
fi

if [ ! -e "ratload" ]; then
    make clean && make
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

cp README.pdf $PRJ_DIR

cp ratload $PRJ_DIR/bin/ratload_nix
