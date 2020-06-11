LINKS= animation.hva emacs.tex activedvi.tex

all: activedvi.gif emacs.gif

animation.hva: 
	ln -s $*.sty $@

emacs.tex: animation.tex
	cp animation.tex $@

activedvi.tex: 
	cp animation.tex $@


%.gif: %.tex animation.sty animation.hva Makefile
	hevea $*.tex
# 	imagen $*
# 	for i in $*00*.png; do convert $$i `basename $$i .png`.gif; done
	imagen -svg $*
	for i in $*00*.svg; do convert $$i `basename $$i .svg`.gif; done
	convert -loop 0 -delay 15 $*00*.gif $*.gif

clean:
	rm -f *.aux *.waux *.wdvi *.haux *.image.* *.dvi *.log *.svg
	rm -f *.html

distclean:
	rm *.gif *.png

.SUFFIXES: .tex .sty .hva .png .gif
