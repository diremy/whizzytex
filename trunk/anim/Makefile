all: activedvi.gif emacs.gif

activedvi.gif: animation.tex animation.sty Makefile
	rm -f $*00*.gif
	hevea $*.tex
	imagen $*
	convert -loop 0 -delay 15 $*00*.gif $*.gif

emacs.gif: animation.tex animation.sty Makefile
	rm -f $*00*.gif
	hevea  $*.tex
	imagen $*
	convert -loop 0 -delay 15 $*00*.gif $*.gif

clean:
	rm -f *.aux *.waux *.wdvi *.haux *.gif *.image.tex *.dvi *.log
	rm -f *.html

.SUFFIXES: .tex .sty .gif .hva 
