HEVEA = hevea -exec xxdate.exe 
HVAOPT = -fix 

DOCSOURCES=manual.tex manual.sty caml.eps version.tex Makefile
DOCFORMATS=dvi ps pdf html info
SHELL = bash
all: FILES

FILES: $(addprefix whizzytex., dvi ps pdf html info) Makefile
	cd ..; \
	ls $(addprefix doc/whizzytex., dvi ps pdf html info) \
	   doc/whizzytex00?.gif doc/whizzytex.info-* \
	   $(addprefix doc/, $(DOCSOURCES)) \
	> doc/$@

manual.hva: manual.sty
	ln -s $< $@

whizzytex.dvi: manual.tex version.tex
	latex $<
	latex $<
	mv manual.dvi $@

whizzytex.ps: whizzytex.dvi
	latex '\def\driver{dvips}\input' manual.tex
	dvips -o $@ manual.dvi

whizzytex.pdf: whizzytex.ps
	ps2pdf $<

whizzytex.html: manual.tex manual.hva whizzytex.dvi 
	$(HEVEA) $(HVAOPT) -o $@ $< && \
	imagen whizzytex

whizzytex.info: manual.tex
	$(HEVEA) $(HVAOPT) -info -o $@ $<

clean:
	rm -f whizzytex.{log,image.*,h{aux,toc}}
	rm -f manual.{aux,log,dvi,toc,dview,wiz,fmt}

distclean: clean
	rm -f whizzytex.{dvi,ps,pdf,html,info} manual.hva


