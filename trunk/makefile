BIN=$(HOME)/bin
TEX=$(HOME)/lib/tex
RELEASE=1.00
VERSION=1.00iii
NAME=whizzytex-$(VERSION)
TAG=.VERSION_$(VERSION)
PACKDIR=packdir


SRCFILES=whizzytex whizzytex.el start.el whizzytex.sty

TARSOURCES = $(patsubst %,src/%,$(SRCFILES)) \
	    GPL COPYING CHANGES \
            Makefile Manager Makefile.config.in \
	    byte-compile.el configure.el \
            configure checkconfig

TARPRODUCED =  INSTALL VERSION 

TARDIRS = doc examples 

TARFILES = $(TARSOURCES) $(TARPRODUCED) $(TARDIRS)


XXXPORTS = CHANGES FAQ.html FAQ

EXPORTS = index.html animation.html Announce \
	   emacs.gif activedvi.gif emacs009.gif activedvi009.gif \
	   manual.dvi doc/manual.html \
	   COPYING GPL INSTALL VERSION \
	   $(XXXPORTS) $(NAME).tgz  

PAUILLAC=pauillac:/net/pauillac/infosystems/www/whizzytex

whatelse: 
	@echo 'make what ? [pack xxxport Export ]'

pack: FILES $(EXPORTS) $(PACKDIR)/checked $(PACKDIR)/whizzytex.elc 

doc/manual.dvi: doc/manual.tex VERSION 
	cd doc; make manual.dvi

manual.dvi: doc/manual.tex
	cp $< $@

FAQ: FAQ.html 
	lynx -dump $< > $@

FAQ.html: FAQ.tex version.tex
	hevea -o $@ -fix -exec xxdate.exe $<

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
	hevea -fix -o $@ $<

INSTALL.txt: doc/manual.html
	lynx -dump $< | sed -f INSTALL.sed > $@




VERSION: makefile
	test `grep '^ORIGIN=' Manager` = 'ORIGIN=$(VERSION)'
	echo $(VERSION) > $@

FILES: $(TARFILES) makefile
	make smallclean
	(echo FILES; echo $(TAG); tar zcvf /dev/null $(TARFILES)) \
	  | grep -v CVS | grep -v '/$$' > $@

$(NAME).tgz: FILES makefile
	mkdir $(NAME)
	touch VERSION $(TAG)
	tar cf - `cat FILES`| (cd $(NAME) && tar xf -)
	tar zcvf $@ $(NAME)
	rm -r $(NAME)

$(PACKDIR)/checked: $(PACKDIR)/.exists $(SOURCES)
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
	touch $@

$(PACKDIR)/.exists:
	mkdir -p $(PACKDIR)
	touch $@

$(PACKDIR)/whizzytex.el: src/whizzytex.el $(PACKDIR)
	cp $< $@

$(PACKDIR)/whizzytex.elc: $(PACKDIR)/whizzytex.el 
	cd $(PACKDIR); emacs --batch -q -l ../byte-compile.el 2> log && \
	cat log && \
	if grep -e '\*\*' log; then rm -f $@; cat log; false; \
	fi
	cd $(PACKDIR); xemacs -batch -q -l ../byte-compile.el 2>log && \
	cat log && \
	if grep -e '\*\*' log; then rm -f $@; false; \
	fi

Export: $(EXPORTS) xxxport
	rcp $(EXPORTS) $(PAUILLAC)
	rcp VERSION $(PAUILLAC)/whizzytex.version
	mv $(NAME).tgz archive

Release: Export 
	cp Announce archive/Announce-$(RELEASE)
	rcp Announce $(PAUILLAC)

xxxport: $(EXPORTS) 
	make NAME=whizzytex-xxx whizzytex-xxx.tgz
	rcp $(XXXPORTS) whizzytex-xxx.tgz $(PAUILLAC)

smallclean:
	cd doc; $(MAKE) clean
	cd examples; $(MAKE) superclean

clean:: smallclean
	rm -rf doc/{*~,.#*,#*#} manual.{aux,log} doc/_whizzy_manual*
	rm -rf $(PACKDIR)

superclean:: clean
	rm -f doc/ocaml.html $(TAG) $(NAME).tgz manual.dvi \
	rm -f *~ .#* #*# FILES 

.in.out:
	./configure < $<

.PHONY: Export xxxport pack

.SUFFIXES: .tgz .in .out .htm .tex .html .gif


include Makefile
