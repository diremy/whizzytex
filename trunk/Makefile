BIN=$(HOME)/bin
EMACS=$(HOME)/lib/gnu-emacs
TEX=$(HOME)/lib/tex

LOCALFILES= bin/whizzytex  lib/tex/whizzytex.sty lib/gnu-emacs/whizzytex.el
SRCFILES=$(patsubst %,$(HOME)/%,$(LOCALFILES))
TESTFILES= manual.tex slides.tex Makefile.tpl

FILES = $(SRCFILES) $(patsubst %,test/%,$(TESTFILES)) CHANGES
       
EXPORTS = index.html whizzytex.tgz whizzytex.dvi whizzytex.html CHANGES

PAUILLAC=pauillac:public_html/whizzytex/

what:
	@echo 'make what ? [all export]'

all: diff $(EXPORTS) whizzytex.elc

whizzytex.dvi: test/manual.tex
	latex $< && mv manual.dvi whizzytex.dvi 

whizzytex.html: test/manual.tex
	hevea -o $@ $< 

whizzytex.tgz: $(FILES) Makefile 
	mkdir tmpdir
	cp $(FILES) tmpdir
	tar -z -cvf $@ tmpdir
	rm -r tmpdir


diff:
	for i in $(LOCALFILES); \
	do diff -q `basename $$i` $(HOME)/$$i || exit 1; done

install:
	for i in $(LOCALFILES); \
	do cp `basename $$i` $(HOME)/$$i; done

whizzytex.el: $(HOME)/lib/gnu-emacs/whizzytex.el
	cp $(HOME)/lib/gnu-emacs/whizzytex.el .

whizzytex.elc: whizzytex.el
	emacs -batch -q -l emacs.el -l compile.el -compile $< 2>$*.log && \
	if grep -e '\*\*' $*.log; then rm -f $@; cat $*.log; false; \
	else rm $*.log; fi
	xemacs -batch -q -l xemacs.el -l compile.el -compile $< 2>$*.log && \
	if grep -e '\*\*' $*.log; then rm -f $@; cat $*.log; false; \
	else rm $*.log; fi

export: $(EXPORTS) whizzytex.elc
	rcp $(EXPORTS) $(PAUILLAC)


smallclean:
	rm -rf {.,test}/*.{aux,log,dvi,dview,ps}

clean: smallclean
	rm -rf whizzytex.tgz *.{aux,log,dvi,dview,ps} 

.SUFFIXES: .tgz
