#!/bin/bash

latex -interaction=nonstopmode README.tex > .tmp
if [ $? -eq 0 ]
then
    dvipdfm README.dvi &> /dev/null
    scp README.pdf host:~/Desktop/ > /dev/null
    scp README.tex host:~/code/nixie_clock/doc > /dev/null
    rm .tmp
else
    cat .tmp
fi
