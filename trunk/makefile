BIN=$(HOME)/bin
TEX=$(HOME)/lib/tex
VERSION=1.0a
NAME=whizzytex-$(VERSION)

LOCALFILES= bin/whizzytex  lib/tex/whizzytex.sty lib/emacs/whizzytex.el
SRCFILES=$(patsubst %,$(HOME)/%,$(LOCALFILES))

FILES= whizzytex whizzytex.sty whizzytex.el
TARFILES = $(FILES) LGPL COPYING INSTALL VERSION \
            Makefile configure configure.el \
	    Makefile.config.in byte-compile.el \
            doc examples 
       
EXPORTS = index.html $(NAME).tgz  manual.dvi manual.html \
           CHANGES COPYING LGPL INSTALL VERSION DATE
PAUILLAC=pauillac:public_html/whizzytex/

What:
	@echo 'make what ? [all export]'

All: diff $(EXPORTS) whizzytex.elc


manual.dvi: doc/manual.tex
	latex $<

manual.html: doc/manual.tex manual.dvi
	hevea -o $@ $<

DATE: $(NAME).tgz VERSION
	echo `cat VERSION`:`date` > DATE

$(NAME).tgz: $(TARFILES) makefile
	make clean
	cd ..; tar -z -cvf whizzytex/$@ $(patsubst %,whizzytex/%,$(TARFILES))

diff:
	for i in $(LOCALFILES); \
	do diff -q `basename $$i` $(HOME)/$$i || exit 1; done

retrieve:
	for i in $(LOCALFILES); \
	do [ $(HOME)/$$i -nt `basename $$i` ] && cp -i $(HOME)/$$i .; done

# install:
# 	for i in $(LOCALFILES); \
# 	do cp `basename $$i` $(HOME)/$$i; done

whizzytex.el: $(HOME)/lib/gnu-emacs/whizzytex.el
	cp $(HOME)/lib/gnu-emacs/whizzytex.el .

whizzytex.elc: whizzytex.el
	emacs --batch -q -l byte-compile.el 2>$*.log && \
	if grep -e '\*\*' $*.log; then rm -f $@; cat $*.log; false; \
	else rm $*.log; fi
	xemacs -batch -q -l byte-compile.el 2>$*.log && \
	if grep -e '\*\*' $*.log; then rm -f $@; cat $*.log; false; \
	else rm $*.log; fi

export: $(EXPORTS) whizzytex.elc
	rcp $(EXPORTS) $(PAUILLAC)
	rsh pauillac \
	  "cd public_html/whizzytex && rm whizzytex.tgz && \
	   ln -s whizzytex-$(VERSION).tgz whizzytex.tgz"


smallclean:
	rm -f {.,test,doc}/*.{aux,log,dvi,dview,ps,wiz,fmt}
	cd examples; $(MAKE) superclean

clean: smallclean
	rm -rf whizzytex.tgz doc/*~

.SUFFIXES: .tgz

include Makefile
