include Makefile.config

SRC=src
TMP=tmp

what:
	@echo 'make what? [ config all install ]'

Makefile.config: 
	@echo '--- Creating default configuration Makefile.config'
	@echo '--- You may edit it or run "make config" for customization'
	cp $@.in $@

.PHONY: all

all: $(TMP)/whizzytex $(TMP)/whizzytex.el \
	$(patsubst %,$(TMP)/%/whizzytex.elc, $(EMACS) $(XEMACS))

.PHONY: default-config config

config: 
	./configure

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

$(TMP)/whizzytex: $(SRC)/whizzytex $(TMP) Makefile.config 
	sed -e 's|PACKAGE=.*|PACKAGE=$(LATEXDIR)/whizzytex.sty|' \
	    -e 's|DVIPS=.*|DVIPS=$(DVIPS)|' \
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
	install -d $(EMACSDIR)
	install $(TMP)/whizzytex.el $(EMACSDIR)
endif
ifneq ($(EMACSDIR),$(XEMACSDIR))
ifdef XEMACSDIR
	install -d $(XEMACSDIR)
	install $(TMP)/whizzytex.el $(XEMACSDIR)
endif
ifdef EMACS
	install $(TMP)/$(EMACS)/whizzytex.elc $(EMACSDIR)
endif
ifdef XEMACS
	install $(TMP)/$(XEMACS)/whizzytex.elc $(XEMACSDIR)
endif
endif
	install -d $(BINDIR)
	install $(TMP)/whizzytex $(BINDIR)
	install -d $(LATEXDIR) && \
	install $(SRC)/whizzytex.sty $(LATEXDIR)
	install -d $(DOCDIR) && \
	install doc/manual.html COPYING GPL INSTALL $(DOCDIR)

clean::
	rm -rf $(TMP)
	cd examples; make clean

veryclean::
	rm -f Makefile.config
