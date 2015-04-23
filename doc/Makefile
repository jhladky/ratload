SHELL := /bin/bash

handbook: handbook.tex
	@pdflatex -interaction=nonstopmode handbook.tex > .tmp || (cat .tmp; exit 1)
	@scp handbook.pdf host:~/Desktop/ > /dev/null
	@rm .tmp

linux_and_osx: linux_and_osx.tex
	@pdflatex -interaction=nonstopmode linux_and_osx.tex > .tmp || (cat .tmp; exit 1)
	@scp linux_and_osx.pdf host:~/Desktop/ > /dev/null
	@rm .tmp

all: handbook linux_and_osx

clean:
	@rm -f handbook.{aux,log,out,pdf,toc}
