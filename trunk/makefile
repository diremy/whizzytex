BIN=$(HOME)/bin
TEX=$(HOME)/lib/tex
VERSION=1.00-alpha
NAME=whizzytex-$(VERSION)

LOCALFILES= bin/whizzytex  lib/tex/whizzytex.sty lib/emacs/whizzytex.el
SRCFILES=$(patsubst %,$(HOME)/%,$(LOCALFILES))

FILES= whizzytex whizzytex.sty whizzytex.el
TARFILES = $(FILES) LGPL COPYING INSTALL VERSION \
	    Makefile.config.in byte-compile.el configure configure.el \
            Makefile Makefile.pkg doc examples 
       
EXPORTS = index.html $(NAME).tgz  manual.dvi doc/manual.html \
           CHANGES COPYING LGPL INSTALL VERSION 
PAUILLAC=pauillac:public_html/whizzytex/

whatelse: 
	@echo 'make what ? [pack export]'

pack: check $(EXPORTS) whizzytex.elc


manual.dvi: doc/manual.tex
	latex $<

doc/manual.html: doc/manual.tex manual.dvi
	hevea -o $@ $<


VERSION: makefile
	test `grep '^VERSION=' Makefile.pkg` = 'VERSION=$(VERSION)'
	test "`grep '^The current version is' index.html | \
	  sed  -e 's/.*="whizzytex-\(.*\)">whizzytex-\(.*\)<.a>/\1,\2/' \
	       `" = '$(VERSION).tgz,$(VERSION).tgz'
	echo $(VERSION) > VERSION

FILES: $(TARFILES) makefile
	make clean
	(echo whizzytex/FILES; \
	 cd ..; tar zcvf /dev/null $(patsubst %,whizzytex/%,$(TARFILES)) \
	) | grep -v CVS | grep -v '/$$' > $@

$(NAME).tgz: FILES
	cd ..; tar zcvf whizzytex/$@ `cat whizzytex/FILES`

check: diff
	@echo ' --- Checking examples'
	cd examples; make >/dev/null

diff:
	for i in $(LOCALFILES); \
	do diff -q `basename $$i` $(HOME)/$$i || exit 1; done

retrieve:
	for i in $(LOCALFILES); \
	do [ $(HOME)/$$i -nt `basename $$i` ] && cp -i $(HOME)/$$i .; done

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

smallclean:
	cd doc; $(MAKE) clean
	cd examples; $(MAKE) superclean

clean:: smallclean
	rm -rf whizzytex.tgz doc/{*~,.#*,#*#}

superclean: clean
	rm -f doc/ocaml.html

.SUFFIXES: .tgz

include Makefile
