include Makefile.config

# REMOTE INSTALLATION
# The prefix to add in front of all files during installation. 

PREFIX=


SRC=src
TMP=tmp

what:
	@echo 'make what? [ config all install clean superclean ]'

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
	touch $@

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
	    -e 's|^DVIPS=.*|DVIPS=$(DVIPS)|' \
	    -e 's|^INITEX=.*|INITEX=$(INITEX)|' \
	    -e 's|^LATEX=.*|LATEX=$(LATEX)|' \
	    -e 's|^LATEXFMT=.*|LATEXFMT=$(LATEXFMT)|' \
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
	install -d $(PREFIX)$(EMACSDIR)
	install $(TMP)/whizzytex.el $(PREFIX)$(EMACSDIR)
endif
ifneq ($(EMACSDIR),$(XEMACSDIR))
ifdef XEMACSDIR
	install -d $(PREFIX)$(XEMACSDIR)
	install $(TMP)/whizzytex.el $(PREFIX)$(XEMACSDIR)
endif
ifdef EMACS
	install $(TMP)/$(EMACS)/whizzytex.elc $(PREFIX)$(EMACSDIR)
endif
ifdef XEMACS
	install $(TMP)/$(XEMACS)/whizzytex.elc $(PREFIX)$(XEMACSDIR)
endif
endif
	install -d $(PREFIX)$(BINDIR)
	install $(TMP)/whizzytex $(PREFIX)$(BINDIR)
	install -d $(PREFIX)$(LATEXDIR) && \
	install $(SRC)/whizzytex.sty $(PREFIX)$(LATEXDIR)
ifdef DOCDIR
	install -d $(PREFIX)$(DOCDIR) && \
	install doc/manual.html COPYING GPL INSTALL $(PREFIX)$(DOCDIR)
endif

.PHONY: uninstall
uninstall: 
ifdef EMACSDIR
	rm -f $(PREFIX)$(EMACSDIR)/whizzytex.{el,elc}
	rmdir $(PREFIX)$(EMACSDIR) 2>/dev/null || true
endif
ifneq ($(EMACSDIR),$(XEMACSDIR))
ifdef XEMACSDIR
	rm -f $(PREFIX)$(EMACSDIR)/whizzytex.{el,elc}
	rmdir $(PREFIX)$(EMACSDIR) 2>/dev/null || true
endif
endif
	rm -f $(PREFIX)$(BINDIR)/whizzytex
	rmdir $(PREFIX)$(BINDIR) 2>/dev/null || true
	rm -f $(PREFIX)$(LATEXDIR)/whizzytex.sty 
	rmdir $(PREFIX)$(LATEXDIR) 2>/dev/null || true
ifdef DOCDIR
	rm -f $(PREFIX)$(DOCDIR)/{doc/manual.html,COPYING,GPL,INSTALL}
	rmdir $(PREFIX)$(DOCDIR) 2>/dev/null || true
endif

clean::
	rm -rf $(TMP)
	rm -f latex.fmt initex.log latex.log dvips.log
	rm -f dummy.{tex,log,aux,dvi,ps}
	rm -f config.ok
	cd examples; make clean

superclean::
	rm -f Makefile.config 
