BIN=$(HOME)/bin
TEX=$(HOME)/lib/tex
RELEASE=1.00
VERSION=1.00i
NAME=whizzytex-$(VERSION)
TAG=.VERSION_$(VERSION)


SRCFILES=whizzytex whizzytex.el start.el whizzytex.sty

TARFILES = $(patsubst %,src/%,$(SRCFILES)) \
	    GPL COPYING INSTALL VERSION CHANGES\
	    Makefile.config.in byte-compile.el configure configure.el \
            Makefile Manager doc examples 
       
EXPORTS = index.html animation.html \
	   emacs.gif activedvi.gif emacs009.gif activedvi009.gif \
	   $(NAME).tgz  manual.dvi doc/manual.html \
           CHANGES COPYING GPL INSTALL VERSION FAQ.html FAQ

PAUILLAC=pauillac:/net/pauillac/infosystems/www/whizzytex

whatelse: 
	@echo 'make what ? [pack export]'

pack: check $(EXPORTS) tardir/whizzytex.elc

doc/manual.dvi: doc/manual.tex VERSION 
	cd doc; make manual.dvi

manual.dvi: doc/manual.dvi
	cp $< $@

FAQ: FAQ.html
	lynx -dump $< > $@

FAQ.html: FAQ.tex
	hevea -o $@ -exec xxdate.exe $<

index.html: index.htm makefile
	sed -e 's/@RELEASE@/$(RELEASE)/g' -e 's/@VERSION@/$(VERSION)/g' $< > $@

animation.html: index.html
	sed -e 's/009.gif/.gif/g' \
	    -e 's/animation.html/index.html/g' $< > $@

emacs.gif: anim/animation.tex anim/animation.sty anim/Makefile
	cd anim; make $@
	cp anim/$*{,009}.gif .

activedvi.gif: anim/animation.tex anim/animation.sty anim/Makefile
	cd anim; make $@
	cp anim/$*{,009}.gif .



doc/manual.html: doc/manual.tex manual.dvi
	hevea -o $@ $<


VERSION: makefile
	test `grep '^ORIGIN=' Manager` = 'ORIGIN=$(VERSION)'
	echo $(VERSION) > $@

FILES: $(TARFILES) makefile
	make clean
	(echo FILES; echo $(TAG); tar zcvf /dev/null $(TARFILES)) \
	  | grep -v CVS | grep -v '/$$' > $@

$(NAME).tgz: FILES makefile
	mkdir $(NAME)
	touch VERSION $(TAG)
	tar cf - `cat FILES`| (cd $(NAME) && tar xf -)
	tar zcvf $@ $(NAME)
	rm -r $(NAME)

check: whizzytex.elc
	@echo ' --- Checking examples'
	cd examples; make >/dev/null
	@echo ' --- src/whizzytex.el'
	grep -e '^\((defvar whizzy-command-name "\)[^"]*\(".*\)$$' \
	   src/whizzytex.el
	grep -e '^\( *\)\(("-advi[^)]*")\) *\(("-dvi[^)]*")\) *$$' \
	   src/whizzytex.el
	@echo ' --- src/whizzytex'
	grep -e '^PACKAGE=[/a-z.][/a-z.]*$$' src/whizzytex
	grep -e '^DVIPS=[a-z][a-z]*$$' src/whizzytex

tardir:
	mkdir -p tardir

tardir/whizzytex.el: src/whizzytex.el tardir
	cp $< $@

tardir/whizzytex.elc: tardir/whizzytex.el 
	cd tardir; emacs --batch -q -l ../byte-compile.el 2> log && \
	cat log && \
	if grep -e '\*\*' log; then rm -f $@; cat log; false; \
	else rm log; fi
	cd tardir; xemacs -batch -q -l ../byte-compile.el 2>log && \
	cat log && \
	if grep -e '\*\*' log; then rm -f $@; false; \
	else rm log; fi

export: $(EXPORTS) xxxport
	rcp $(EXPORTS) $(PAUILLAC)
	rcp VERSION $(PAUILLAC)/whizzytex.version
	mv $(NAME).tgz archive

xxxport: 
	make NAME=whizzytex-xxx whizzytex-xxx.tgz
	rcp whizzytex-xxx.tgz $(PAUILLAC)

smallclean:
	cd doc; $(MAKE) clean
	cd examples; $(MAKE) superclean

clean:: smallclean
	rm -rf doc/{*~,.#*,#*#} manual.{aux,log} doc/_whizzy_manual*
	rm -rf tardir

superclean: clean
	rm -f doc/ocaml.html $(TAG) $(NAME).tgz manual.dvi \
	rm -f *~ .#* #*# FILES 

.in.out:
	./configure < $<

.SUFFIXES: .tgz .in .out .htm .tex .html .gif

include Makefile
