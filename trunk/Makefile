include Makefile.config

what:
	@echo 'make what? [ config all install ]'

.PHONY: all
all: prep/whizzytex.el prep/whizzytex.elc prep/whizzytex

.PHONY: config
config: 
	./configure

prep: 
	if test -d prep; then : ; else mkdir -p prep; fi

prep/whizzytex.el: whizzytex.el prep
	sed -e 's|\((defvar whizzy-command-name "\)[^"]*\(".*\)|\1$(BASHDIR)/whizzytex\2|' \
	 <  $< > $@

prep/whizzytex.elc: prep/whizzytex.el
	cd prep; $(EMACS) -batch -q -l $(PWD)/byte-compile.el

prep/whizzytex: whizzytex prep 
	sed -e 's|PACKAGE=.*|PACKAGE=$(LATEXDIR)/whizzytex.sty|' \
	 <  $< > $@
	chmod +x $@

clean:
	rm -rf prep


.PHONY: install
install: all
	@echo "Installing whizzytex.el in $(EMACSDIR)..."
	if test -d $(EMACSDIR); then : ; else mkdir -p $(EMACSDIR); fi
	cp prep/whizzytex.el prep/whizzytex.elc $(EMACSDIR)
	@echo "Installing whizzytex in $(BASHDIR)..."
	if test -d $(BASHDIR); then : ; else mkdir -p $(BASHDIR); fi
	cp prep/whizzytex $(BASHDIR)
	@echo "Installing whizzytex.sty in $(LATEXDIR)..."
	if test -d $(LATEXDIR); then : ; else mkdir -p $(LATEXDIR); fi
	cp whizzytex.sty $(LATEXDIR)
