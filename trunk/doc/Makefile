HEVEA = hevea -exec xxdate.exe 
HVAOPT = -fix -nosymb
# HVAOPT = -charset iso-8859-1 -fix -nosymb

all: manual.dvi manual.html whizzytex.info

manual.hva: manual.sty
	ln -s $< $@

manual.ps: manual.dvi
manual.dvi: manual.tex version.tex
	latex $<
	latex '\def\driver{dvips}\input' $<
	dvips -o $*.ps $*.dvi
	latex $<

manual.html: manual.hva manual.tex manual.dvi 
	$(HEVEA) $(HVAOPT) -o $@ $< && \
	imagen manual

whizzytex.info: manual.tex
	$(HEVEA) $(HVAOPT) -o $@ $<

clean:
	rm -f {whizzytex,manual}.{aux,log,dvi,dview,wiz,fmt}
	rm -f {whizzytex,manual}.{haux,htoc,waux,advi}

