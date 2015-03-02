#!/bin/bash

pdflatex -interaction=nonstopmode README.tex > .tmp
if [ $? -eq 0 ]
then
    scp README.pdf host:~/Desktop/ > /dev/null
    rm .tmp
else
    cat .tmp
    exit 1
fi

pdflatex -interaction=nonstopmode linux_and_osx.tex > .tmp
if [ $? -eq 0 ]
then
    scp linux_and_osx.pdf host:~/Desktop/ > /dev/null
    rm .tmp
else
    cat .tmp
fi


