include Makefile.config

what:
	@echo 'make what? [ config all install ]'

Makefile.config: 
	@echo 'run "make config" by hand to create $@'

.PHONY: all

all: prep/whizzytex prep/whizzytex.el \
	$(patsubst %,prep/%/whizzytex.elc, $(EDITORS))

.PHONY: config

config: 
	@if test -f Makefile.config; then \
	 echo -n 'Do you wish to override Makefile.config? (y/n) [n] '; \
	 read; if test "$REPLY" != y; then exit 2; fi; fi
	./configure

prep: 
	mkdir -p $@ $@/$(EMACS) $@/$(XEMACS)

prep/whizzytex.el: whizzytex.el prep
	sed -e 's|\((defvar whizzy-command-name "\)[^"]*\(".*\)|\1$(BASHDIR)/whizzytex\2|' \
	 <  $< > $@

ifdef EMACS
prep/$(EMACS)/whizzytex.elc: prep/whizzytex.el byte-compile.el
	cd prep/$(EMACS); cp ../whizzytex.el .; \
	$(EMACS) -batch -q -l $(PWD)/byte-compile.el
endif

ifdef XEMACS
prep/$(XEMACS)/whizzytex.elc: prep/whizzytex.el byte-compile.el 
	cd prep/$(XEMACS); cp ../whizzytex.el .; \
	$(XEMACS) -batch -q -l $(PWD)/byte-compile.el
endif

prep/whizzytex: whizzytex prep 
	sed -e 's|PACKAGE=.*|PACKAGE=$(LATEXDIR)/whizzytex.sty|' \
	 <  $< > $@
	chmod +x $@

.PHONY: install
install: all
ifdef EMACS
	@if ! test -d '$(EMACSDIR)'; \
	 then echo '$(EMACSDIR) is not a directory'; exit 1; fi
	install prep/whizzytex.el prep/$(EMACS)/whizzytex.elc $(EMACSDIR)
endif
ifdef XEMACS
	@if ! test -d '$(XEMACSDIR)';  \
	 then echo '$(XEMACSDIR) is not a directory'; exit 1; fi
	install prep/whizzytex.el prep/$(XEMACS)/whizzytex.elc $(XEMACSDIR)
endif
	install -d $(BASHDIR)
	install prep/whizzytex $(BASHDIR)
	install -d $(LATEXDIR) && \
	install whizzytex.sty $(LATEXDIR)

clean::
	rm -rf prep
	cd examples; make clean

