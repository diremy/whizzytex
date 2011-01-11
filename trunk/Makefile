include Makefile.config

# REMOTE INSTALLATION
# The prefix to add in front of all files during installation. 

DESTDIR=


SRC=src
TMP=tmp
INSTALLX=install
INSTALLR=install -m 0644

INSTALLED = whizzytex.installed

what:
	@echo 'make what? [ config all install clean distclean uninstall ]'

Makefile.config: 
	@echo '--- Creating default configuration Makefile.config'
	@echo '--- You may edit it or run "make config" for customization'
	cp $@.in $@

ALL = $(TMP)/whizzytex $(TMP)/whizzytex.el \
	$(patsubst %,$(TMP)/%/whizzytex.elc, $(EMACS) $(XEMACS))

.PHONY: all
all: config.checked $(ALL)

.PHONY: config config.force

config: 
	bash ./configure

config.checked: Makefile.config 
	bash ./checkconfig config.checked

config.force: 
	touch config.checked

$(TMP): 
	rm -f $(TMP)
	mkdir -p $@ 

$(TMP)/whizzytex.el: $(SRC)/whizzytex.el $(TMP) Makefile.config
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
	$(EMACS) -batch -q -no-site-file -l ../../byte-compile.el
endif

ifdef XEMACS
$(TMP)/$(XEMACS): $(TMP)
	mkdir -p $@

$(TMP)/$(XEMACS)/whizzytex.elc: $(TMP)/$(XEMACS)
$(TMP)/$(XEMACS)/whizzytex.elc: $(TMP)/whizzytex.el byte-compile.el 
	cd $(TMP)/$(XEMACS); cp ../whizzytex.el .; \
	$(XEMACS) -batch -q -no-site-file -l ../../byte-compile.el
endif

$(TMP)/whizzytex: $(SRC)/whizzytex $(TMP) Makefile.config
	sed -e '1s|^#!/bin/bash *$$|#!$(BASH)|' \
	    -e 's|^PACKAGE=.*|PACKAGE=$(LATEXDIR)/whizzytex.sty|' \
	    -e 's|^MULTIPLE=.*|MULTIPLE=$(MULTIPLE)|' \
	    -e 's|^DVIPS=.*|DVIPS="$(DVIPS)"|' \
	    -e 's|^CONFIGFILE=.*|CONFIGFILE=$(CONFIGFILE)|' \
	    -e 's|^INITEX=.*|INITEX="$(INITEX)"|' \
	    -e 's|^LATEX=.*|LATEX="$(LATEX)"|' \
	    -e 's|^FORMAT=.*|FORMAT="$(FORMAT)"|' \
	    -e 's|^FMT=.*|FMT=$(FMT)|' \
	    -e 's|^BIBTEX=.*|BIBTEX="$(BIBTEX)"|' \
	 <  $< > $@
	chmod +x $@

ifdef EMACSDIR
whizzytex-emacs-init.el: $(SRC)/whizzytex-init.el
	@sed -e 's|^\( *"\)[^ ]*\(" *\)$$|\1$(EMACSDIR)/whizzytex\2|' $<
endif

ifdef XEMACSDIR
whizzytex-xemacs-init.el: $(SRC)/whizzytex-init.el
	@sed -e 's|^\( *"\)[^ ]*\(" *\)$$|\1$(XEMACSDIR)/whizzytex\2|' $<
endif

.PHONY: install
install: all
	@[ -f config.checked ] || ( \
	echo 'Warning!' && \
	echo '  Your Makefile.config has not been checked.' && \
	echo '  Run "make config.checked" (or "make all") to check it,' && \
	echo '  or  "make config.force"  to accept it as is.' && \
	false)
ifdef EMACSDIR
	rm -f $(INSTALLED)
	mkdir -p $(DESTDIR)$(EMACSDIR)
	$(INSTALLR) $(TMP)/whizzytex.el $(DESTDIR)$(EMACSDIR)
	echo $(DESTDIR)$(EMACSDIR)/whizzytex.el >> $(INSTALLED)
	rm -f $(DESTDIR)$(EMACSDIR)/whizzytex.elc
ifdef EMACS
	$(INSTALLR) $(TMP)/$(EMACS)/whizzytex.elc $(DESTDIR)$(EMACSDIR)
	echo $(DESTDIR)$(EMACSDIR)/whizzytex.elc >> $(INSTALLED)
endif
endif
ifdef XEMACSDIR
	mkdir -p $(DESTDIR)$(XEMACSDIR)
	$(INSTALLR) $(TMP)/whizzytex.el $(DESTDIR)$(XEMACSDIR)
	echo $(DESTDIR)$(XEMACSDIR)/whizzytex.el >> $(INSTALLED)
	rm -f $(DESTDIR)$(XEMACSDIR)/whizzytex.elc
ifdef XEMACS
	cp $(TMP)/$(XEMACS)/whizzytex.elc $(DESTDIR)$(XEMACSDIR)
	echo $(DESTDIR)$(XEMACSDIR)/whizzytex.elc >> $(INSTALLED)
endif
endif
	mkdir -p $(DESTDIR)$(BINDIR)
	$(INSTALLX) $(TMP)/whizzytex $(DESTDIR)$(BINDIR)
	echo $(DESTDIR)$(BINDIR)/whizzytex >> $(INSTALLED)
	mkdir -p $(DESTDIR)$(LATEXDIR) 
	$(INSTALLR) $(SRC)/whizzytex.sty $(DESTDIR)$(LATEXDIR)
	echo $(DESTDIR)$(LATEXDIR)/whizzytex.sty >> $(INSTALLED)
	mkdir -p $(DESTDIR)$(DOCDIR) 
	$(INSTALLR) doc/whizzytex.html COPYING GPL INSTALL $(DESTDIR)$(DOCDIR)
	for i in doc/whizzytex.html COPYING GPL INSTALL; \
	 do echo $(DOCDIR)/$$i; done >> $(INSTALLED)

where:
ifdef EMACSDIR
	@echo 'Emacs Lisp in EMACSDIR=$(DESTDIR)$(EMACSDIR)'
ifdef EMACS
	@echo 'Byte-compiled Emacs Lisp in EMACSDIR=$(DESTDIR)$(EMACSDIR)'
endif
endif
ifdef XEMACSDIR
	@echo 'XEmacs Lisp in XEMACSDIR=$(XEMACSDIR)'
ifdef XEMACS
	@echo 'Byte-compiled XEmacs Lisp  in XEMACSDIR=$(DESTDIR)$(XEMACSDIR)'
endif
endif
	@echo 'Script  in BINDIR=$(DESTDIR)$(BINDIR)'
	@echo 'Latex macros  in LATEXDIR=$(DESTDIR)$(LATEXDIR)'
	@echo 'Documentation  in DOCDIR=$(DESTDIR)$(DOCDIR)'

.PHONY: uninstall
uninstall: $(INSTALLED)
	rm -f `cat $(INSTALLED)`
	rm -f $(INSTALLED)


clean::
	rm -rf $(TMP)
	rm -f latex.fmt initex.log latex.log dvips.log
	rm -f dummy.{tex,fmt,log,aux,dvi,ps}
	rm -f config.error config.sed
	cd examples; make clean

distclean:: clean
	rm -f Makefile.config config.checked
