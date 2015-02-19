#!/bin/bash

pdflatex -interaction=nonstopmode README.tex > .tmp
if [ $? -eq 0 ]
then
    scp README.pdf host:~/Desktop/ > /dev/null
    scp README.tex host:~/code/ratload/doc > /dev/null
    rm .tmp
else
    cat .tmp
fi
