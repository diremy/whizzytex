all: manual.dvi manual.html whizzytex.info


manual.dvi: manual.tex version.tex
	latex $<
	if grep 'LaTeX Warning: Label(s)' $*.log; then latex $<; fi

version.tex: ../VERSION ../RELEASE
	(echo '\def\release{'`cat ../RELEASE`'}' ; \
	echo '\def\version{'`cat ../VERSION`'}' ) > $@


manual.html: manual.tex manual.dvi
	hevea -fix -nosymb -o $@ $<

whizzytex.info: manual.tex
	hevea -fix -nosymb -info -o $@ $<

clean:
	rm -f {whizzytex,manual}.{aux,log,dvi,dview,wiz,fmt}
	rm -f {whizzytex,manual}.{haux,htoc,waux,advi}

