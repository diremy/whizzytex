HEVEA = hevea -exec xxdate.exe 
HVAOPT = -fix -nosymb
# HVAOPT = -charset iso-8859-1 -fix -nosymb

all: manual.dvi manual.html whizzytex.info


manual.dvi: manual.tex version.tex
	latex $<
	if grep 'LaTeX Warning: Label(s)' $*.log; then latex $<; fi

manual.html: manual.tex manual.dvi
	$(HEVEA) $(HVAOPT) -o $@ $< && \
	imagen manual

whizzytex.info: manual.tex
	$(HEVEA) $(HVAOPT) -o $@ $<

clean:
	rm -f {whizzytex,manual}.{aux,log,dvi,dview,wiz,fmt}
	rm -f {whizzytex,manual}.{haux,htoc,waux,advi}

