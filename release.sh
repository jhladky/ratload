#!/bin/bash

VER=`cat .version`
PRJ_DIR="release_v$VER"

if [ -e $PRJ_DIR ]; then
    rm -rf $PRJ_DIR;
fi

if [ -e release_v$VER.log ]; then
    rm release_v$VER.log
fi

if [ -e release_v$VER.zip ]; then
    rm release_v$VER.zip
fi

if [ ! -e "doc/README.pdf" ]; then
    echo "README.pdf not found, exiting..."
    exit 1
fi

if [ ! -e "src/ratload_Windows_x86.exe" ]; then
    cd src
    make clean && make
    cd ..
fi

if [ -d "src/ratload_v$VER/" ]; then
    rm -rf src/ratload_v$VER
fi

cd src
/cygdrive/c/Python34/python.exe setup.py py2exe &>> ../release_v$VER.log
rm -rf __pycache__ 
mv dist ratload_v$VER
cd ..

mkdir $PRJ_DIR
mkdir $PRJ_DIR/vhdl

# Top-Level Modules
cp RAT_CPU/rat_wrapper.vhd $PRJ_DIR/vhdl/
cp RAT_CPU/inputs.vhd $PRJ_DIR/vhdl/
cp RAT_CPU/outputs.vhd $PRJ_DIR/vhdl/

# Random Number Generator I/O Device
cp RAT_CPU/random.vhd $PRJ_DIR/vhdl/

# UART I/O Device
cp RAT_CPU/uart.vhd $PRJ_DIR/vhdl/
cp RAT_CPU/RS232RefComp.vhd $PRJ_DIR/vhdl/
cp RAT_CPU/ascii_to_int.vhd $PRJ_DIR/vhdl/
cp RAT_CPU/int_to_ascii.vhd $PRJ_DIR/vhdl/

# 7-Segment Display I/O Device
cp RAT_CPU/sseg_dec.vhd $PRJ_DIR/vhdl/
cp RAT_CPU/clk_div_sseg.vhd $PRJ_DIR/vhdl/

# Prog-Rom Module
cp RAT_CPU/interceptor.vhd $PRJ_DIR/vhdl/
cp RAT_CPU/prog_rom.vhd $PRJ_DIR/vhdl/
cp RAT_CPU/prog_ram.vhd $PRJ_DIR/vhdl/
cp RAT_CPU/real_prog_rom.vhd $PRJ_DIR/vhdl/
cp SERIAL_TEST/prog_rom.vhd $PRJ_DIR/vhdl/serial_test.vhd

cp doc/README.pdf $PRJ_DIR

cp -ar src/ratload_v$VER $PRJ_DIR/
cp src/ratload_Windows_x86.exe $PRJ_DIR/ratload_v$VER/
cp src/ratload_logo.png $PRJ_DIR/ratload_v$VER/

zip -r release_v$VER release_v$VER &>> release_v$VER.log
rm -rf release_v$VER
