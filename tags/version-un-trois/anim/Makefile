LINKS= animation.hva emacs.tex activedvi.tex

all: activedvi.gif emacs.gif

animation.hva: 
	ln -s $*.sty $@

emacs.tex: 
	ln -s animation.tex $@

activedvi.tex: 
	ln -s animation.tex $@


activedvi.gif: animation.tex animation.sty animation.hva activedvi.tex Makefile
	rm -f $*00*.gif
	hevea $*.tex
	imagen $*
	convert -loop 0 -delay 15 $*00*.gif $*.gif

emacs.gif: animation.tex animation.sty animation.hva emacs.tex Makefile
	rm -f $*00*.gif
	hevea  $*.tex
	imagen $*
	convert -loop 0 -delay 15 $*00*.gif $*.gif

clean:
	rm -f *.aux *.waux *.wdvi *.haux *.image.tex *.dvi *.log
	rm -f *.html

distclean:
	rm *.gif

.SUFFIXES: .tex .sty .gif .hva 
