include Makefile.config

# REMOTE INSTALLATION
# The prefix to add in front of all files during installation. 

INSTALLPREFIX=


SRC=src
TMP=tmp
INSTALLX=install
INSTALLR=install -m 0644

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
	$(INSTALLR) $(TMP)/whizzytex.el $(EMACSDIR)
	echo $(EMACSDIR)/whizzytex.el >> Manager.installed
	rm -f $(EMACSDIR)/whizzytex.elc
ifdef EMACS
	cp $(TMP)/$(EMACS)/whizzytex.elc $(EMACSDIR)
	echo $(EMACSDIR)/whizzytex.elc >> Manager.installed
endif
endif
ifdef XEMACSDIR
	mkdir -p $(XEMACSDIR)
	$(INSTALLR) $(TMP)/whizzytex.el $(XEMACSDIR)
	echo $(XEMACSDIR)/whizzytex.el >> Manager.installed
	rm -f $(XEMACSDIR)/whizzytex.elc
ifdef XEMACS
	cp $(TMP)/$(XEMACS)/whizzytex.elc $(XEMACSDIR)
	echo $(XEMACSDIR)/whizzytex.elc >> Manager.installed
endif
endif
	mkdir -p $(BINDIR)
	$(INSTALLX) $(TMP)/whizzytex $(BINDIR)
	echo $(BINDIR)/whizzytex >> Manager.installed
	mkdir -p $(LATEXDIR) 
	$(INSTALLR) $(SRC)/whizzytex.sty $(LATEXDIR)
	echo $(LATEXDIR)/whizzytex.sty >> Manager.installed
	mkdir -p $(DOCDIR) 
	$(INSTALLR) doc/manual.html COPYING GPL INSTALL $(DOCDIR)
	for i in manual.html COPYING GPL INSTALL; \
	 do echo $(DOCDIR)/$$i; done >> Manager.installed

where:
ifdef EMACSDIR
	@echo 'Emacs Lisp in EMACSDIR=$(EMACSDIR)'
ifdef EMACS
	@echo 'Byte-compiled Emacs Lisp in EMACSDIR=$(EMACSDIR)'
endif
endif
ifdef XEMACSDIR
	@echo 'XEmacs Lisp in XEMACSDIR=$(XEMACSDIR)'
ifdef XEMACS
	@echo 'Byte-compiled XEmacs Lisp  in XEMACSDIR=$(XEMACSDIR)'
endif
endif
	@echo 'Script  in BINDIR=$(BINDIR)'
	@echo 'Latex macros  in LATEXDIR=$(LATEXDIR)'
	@echo 'Documentation  in DOCDIR=$(DOCDIR)'

.PHONY: uninstall
uninstall: Manager.installed
	rm -f `cat Manager.installed`
	rm -f Manager.installed


clean::
	rm -rf $(TMP)
	rm -f latex.fmt initex.log latex.log dvips.log
	rm -f dummy.{tex,fmt,log,aux,dvi,ps}
	rm -f config.error config.sed
	cd examples; make clean

distclean:: clean
	rm -f Makefile.config config.ok 
