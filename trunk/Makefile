include Makefile.config

# REMOTE INSTALLATION
# The prefix to add in front of all files during installation. 

INSTALLPREFIX=


SRC=src
TMP=tmp

what:
	@echo 'make what? [ config all install clean distclean uninstall ]'

Makefile.config: 
	@echo '--- Creating default configuration Makefile.config'
	@echo '--- You may edit it or run "make config" for customization'
	cp $@.in $@

.PHONY: all
all: $(TMP)/whizzytex $(TMP)/whizzytex.el \
	$(patsubst %,$(TMP)/%/whizzytex.elc, $(EMACS) $(XEMACS))

.PHONY: config config.force

config: 
	bash ./configure

config.ok: Makefile.config 
	bash ./checkconfig

config.force: 
	touch config.ok

$(TMP): 
	rm -f $(TMP)
	mkdir -p $@ 

$(TMP)/whizzytex.el: $(SRC)/whizzytex.el $(TMP) config.ok
ifndef ADVI
	sed -e 's|\((defvar whizzy-command-name "\)[^"]*\(".*\)|\1$(BINDIR)/whizzytex\2|' \
	    -e 's|^\( *\)\(("-advi[^)]*")\) *\(("-dvi[^)]*")\)|\1\3 \2|' \
	 <  $< > $@
else
	sed -e 's|\((defvar whizzy-command-name "\)[^"]*\(".*\)|\1$(BINDIR)/whizzytex\2|' \
	 <  $< > $@
endif

ifdef EMACS
$(TMP)/$(EMACS): $(TMP)
	mkdir -p $@

$(TMP)/$(EMACS)/whizzytex.elc: $(TMP)/$(EMACS) 
$(TMP)/$(EMACS)/whizzytex.elc: $(TMP)/whizzytex.el byte-compile.el 
	cd $(TMP)/$(EMACS); cp ../whizzytex.el .; \
	$(EMACS) -batch -q -l ../../byte-compile.el
endif

ifdef XEMACS
$(TMP)/$(XEMACS): $(TMP)
	mkdir -p $@

$(TMP)/$(XEMACS)/whizzytex.elc: $(TMP)/$(XEMACS)
$(TMP)/$(XEMACS)/whizzytex.elc: $(TMP)/whizzytex.el byte-compile.el 
	cd $(TMP)/$(XEMACS); cp ../whizzytex.el .; \
	$(XEMACS) -batch -q -l ../../byte-compile.el
endif

$(TMP)/whizzytex: $(SRC)/whizzytex $(TMP) config.ok
	sed -e '1s|^#!/bin/bash *$$|#!$(BASH)|' \
	    -e 's|^PACKAGE=.*|PACKAGE=$(LATEXDIR)/whizzytex.sty|' \
	    -e 's|^GREPB=.*|GREPB=$(GREPB)|' \
	    -e 's|^DVIPS=.*|DVIPS=$(DVIPS)|' \
	    -e 's|^INITEX=.*|INITEX=$(INITEX)|' \
	    -e 's|^LATEX=.*|LATEX=$(LATEX)|' \
	    -e 's|^FORMAT=.*|FORMAT=$(FORMAT)|' \
	    -e 's|^FMT=.*|FMT=$(FMT)|' \
	 <  $< > $@
	chmod +x $@

ifdef EMACSDIR
start-emacs.el: $(SRC)/start.el
	@sed -e 's|^\( *"\)[^ ]*\(" *\)$$|\1$(EMACSDIR)/whizzytex\2|' $<
endif

ifdef XEMACSDIR
start-xemacs.el: $(SRC)/start.el
	@sed -e 's|^\( *"\)[^ ]*\(" *\)$$|\1$(XEMACSDIR)/whizzytex\2|' $<
endif

.PHONY: install
install: all
ifdef EMACSDIR
	mkdir -p $(EMACSDIR)
	cp $(TMP)/whizzytex.el $(EMACSDIR)
ifdef EMACS
	cp $(TMP)/$(EMACS)/whizzytex.elc $(EMACSDIR)
endif
endif
ifdef XEMACSDIR
	mkdir -p $(XEMACSDIR)
	cp $(TMP)/whizzytex.el $(XEMACSDIR)
ifdef XEMACS
	cp $(TMP)/$(XEMACS)/whizzytex.elc $(XEMACSDIR)
endif
endif
	mkdir -p $(BINDIR)
	cp $(TMP)/whizzytex $(BINDIR)
	mkdir -p $(LATEXDIR) && \
	cp $(SRC)/whizzytex.sty $(LATEXDIR)
	mkdir -p $(DOCDIR) && \
	cp doc/manual.html COPYING GPL INSTALL $(DOCDIR)

.PHONY: uninstall
uninstall: 
ifdef EMACSDIR
	rm -f  $(EMACSDIR)/whizzytex.{el,elc}
	rmdir $(EMACSDIR) 2>/dev/null || true
endif
ifdef XEMACSDIR
	rm -f $(XEMACSDIR)/whizzytex.{el,elc}
	rmdir $(XEMACSDIR) 2>/dev/null || true
endif
	rm -f $(BINDIR)/whizzytex
	rmdir $(BINDIR) 2>/dev/null || true
	rm -f $(LATEXDIR)/whizzytex.sty 
	rmdir $(LATEXDIR) 2>/dev/null || true
	rm -f $(DOCDIR)/{manual.html,COPYING,GPL,INSTALL}
	rmdir $(DOCDIR) 2>/dev/null || true

clean::
	rm -rf $(TMP)
	rm -f latex.fmt initex.log latex.log dvips.log
	rm -f dummy.{tex,fmt,log,aux,dvi,ps}
	rm -f config.error config.sed
	cd examples; make clean

distclean:: clean
	rm -f Makefile.config config.ok 
