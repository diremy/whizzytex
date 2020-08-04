HEVEA = hevea -exec xxdate.exe 
# HVAOPT = -fix 

DOCSOURCES=manual.tex manual.sty caml.eps version.tex Makefile
DOCFORMATS=dvi ps pdf html info
SHELL = bash
all: FILES

FILES: $(addprefix whizzytex., dvi ps pdf html info) \
	Makefile whizzytex.info.head
	cd ..; \
	ls $(addprefix doc/whizzytex., dvi ps pdf html info) \
	   doc/whizzytex00?.png doc/whizzytex.info-* doc/whizzytex.info.head \
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
	imagen whizzytex && \
	$(HEVEA) $(HVAOPT) -o $@ $< 

whizzytex.info: manual.tex whizzytex.info.head
	$(HEVEA) $(HVAOPT) -info -o $@ $<
	tail -n +2 $@ | cat whizzytex.info.head - > $@.tmp
	mv $@.tmp $@

clean:
	rm -f whizzytex.log whizzytex.image.* whizzytex.haux whizzytex.htoc
	rm -f manual.aux manual.log manual.dvi manual.toc \
	      manual.dview manual.wiz manual.fmt

# rm -f whizzytex.{log,image.*,h{aux,toc}}
# rm -f manual.{aux,log,dvi,toc,dview,wiz,fmt}

distclean: clean
	rm -f whizzytex.dvi whizzytex.ps whizzytex.pdf whizzytex.html \
	      whizzytex.info manual.html

# Keep caml.eps and gif files: hard to remake


