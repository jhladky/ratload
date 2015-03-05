#!/bin/bash

OS=`uname`
VER=`cat .version`
PRJ_DIR="release_v$VER"

if [ ! -e "doc/README.pdf" ]; then
    echo "README.pdf not found! Exit."
    exit 1
fi

if [ "$OS" = "CYGWIN_NT-6.1" ]; then
    printf "Rebuilding ratload..........."
    cd src

    if [ -d "ratload_v$VER" ]; then
        rm -rf ratload_v$VER
    fi

    make clean && make &>> ../release_v$VER.log
    /cygdrive/c/Python34/python.exe setup.py py2exe &>> ../release_v$VER.log
    rm -rf __pycache__ 
    mv dist ratload_v$VER
    cd ..
    cp .version src/ratload_v$VER
    printf "DONE\n"
fi

printf "Removing old release files..."
rm -rf $PRJ_DIR
rm -f release_v$VER.log
rm -f release_v$VER.zip
printf "DONE\n"

printf "Copying RAT files............"
mkdir $PRJ_DIR
mkdir $PRJ_DIR/new_rat_wrapper
mkdir $PRJ_DIR/new_prog_rom

# Top-Level Modules
cp RAT_CPU/rat_wrapper.vhd $PRJ_DIR/new_rat_wrapper/
cp RAT_CPU/inputs.vhd $PRJ_DIR/new_rat_wrapper/
cp RAT_CPU/outputs.vhd $PRJ_DIR/new_rat_wrapper/
cp RAT_CPU/rat_wrapper.ucf $PRJ_DIR/new_rat_wrapper/rat_wrapper_nexys2.ucf
cp RAT_CPU/rat_wrapper_nexys3.ucf $PRJ_DIR/new_rat_wrapper/

# Copy the testing folder verbatim
cp -ar testing $PRJ_DIR/

# Random Number Generator I/O Device
cp RAT_CPU/random.vhd $PRJ_DIR/new_rat_wrapper/

# UART I/O Device
cp RAT_CPU/uart_wrapper.vhd $PRJ_DIR/new_rat_wrapper/
cp uart/source/uart.vhd     $PRJ_DIR/new_rat_wrapper/
cp RAT_CPU/ascii_to_int.vhd $PRJ_DIR/new_rat_wrapper/
cp RAT_CPU/int_to_ascii.vhd $PRJ_DIR/new_rat_wrapper/

# 7-Segment Display I/O Device
cp RAT_CPU/sseg_dec.vhd $PRJ_DIR/new_rat_wrapper/
cp RAT_CPU/clk_div_sseg.vhd $PRJ_DIR/new_rat_wrapper/

# Prog-Rom Module
cp RAT_CPU/interceptor.vhd $PRJ_DIR/new_prog_rom/
cp RAT_CPU/prog_rom.vhd $PRJ_DIR/new_prog_rom/
cp RAT_CPU/prog_ram.vhd $PRJ_DIR/new_prog_rom/
cp RAT_CPU/real_prog_rom.vhd $PRJ_DIR/new_prog_rom/

cp doc/README.pdf $PRJ_DIR
cp doc/linux_and_osx.pdf $PRJ_DIR

cp -ar src/ratload_v$VER $PRJ_DIR/
cp src/ratload_Windows_x86.exe $PRJ_DIR/ratload_v$VER/
cp src/ratload_logo.png $PRJ_DIR/ratload_v$VER/
printf "DONE\n"

printf "Zipping and cleaning up......"
zip -r release_v$VER release_v$VER &>> release_v$VER.log
rm -rf release_v$VER
printf "DONE\n"
