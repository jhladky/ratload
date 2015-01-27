#!/bin/bash

latex -interaction=nonstopmode README.tex > .tmp
if [ $? -eq 0 ]
then
    dvipdfm README.dvi &> /dev/null
    rm .tmp
else
    cat .tmp
fi
