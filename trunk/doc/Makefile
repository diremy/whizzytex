manual.dvi: manual.tex version.tex
	latex $<
	if grep 'LaTeX Warning: Label(s)' $*.log; then latex $<; fi

version.tex: ../VERSION
	echo '\def\version{'`cat $<`'}' > $@

clean:
	rm -f manual.{aux,log,dvi,dview,wiz,fmt}
	rm -f manual.{haux,htoc}
	rm -rf .advi

