include Makefile.config

what:
	@echo 'make what? [ config all install ]'

TGZ=whizzytex.tgz

update:   
	mkdir tmp
	cd tmp; wget $(URL)/DATE
	if diff DATE tmp/DATE; then \
	echo `cat $DATE` up-to-date; exit 0; else \
	(cd tmp; wget $(URL)/$(TGZ) && mv $(TGZ) ..); fi
	rm -rf tmp

promote: $(TGZ)
	(cd ..; gunzip -c whizzytex/whizzytex.tgz | tar -xvf -)


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
	if test -d $@; then : ; else mkdir -p $@; fi

prep/$(EMACS): 
	if test -d $@; then : ; else mkdir -p $@; fi

prep/$(XEMACS): 
	if test -d $@; then : ; else mkdir -p $@; fi

prep/whizzytex.el: whizzytex.el prep
	sed -e 's|\((defvar whizzy-command-name "\)[^"]*\(".*\)|\1$(BASHDIR)/whizzytex\2|' \
	 <  $< > $@

prep/$(EMACS)/whizzytex.elc: prep/whizzytex.el prep/$(EMACS)
	cd prep/$(EMACS); cp ../whizzytex.el .; \
	$(EMACS) -batch -q -l $(PWD)/byte-compile.el

prep/$(XEMACS)/whizzytex.elc: prep/whizzytex.el prep/$(XEMACS)
	cd prep/$(XEMACS); cp ../whizzytex.el .; \
	$(XEMACS) -batch -q -l $(PWD)/byte-compile.el

prep/whizzytex: whizzytex prep 
	sed -e 's|PACKAGE=.*|PACKAGE=$(LATEXDIR)/whizzytex.sty|' \
	 <  $< > $@
	chmod +x $@

clean:
	rm -rf prep


.PHONY: install
install: all
	@echo; echo "## Installing whizzytex.el in $(EMACSDIR)"
	if test -n "$(EMACSDIR)"; then \
	  install -d $(EMACSDIR); \
	  install prep/whizzytex.el prep/$(EMACS)/whizzytex.elc $(EMACSDIR); fi
	@echo; echo "## Installing whizzytex.el in $(XEMACSDIR)"
	if test -n "$(XEMACSDIR)"; then \
	  install -d $(XEMACSDIR) && \
	  install prep/whizzytex.el prep/$(XEMACS)/whizzytex.elc \
		$(XEMACSDIR); fi
	@echo; echo "## Installing whizzytex in $(BASHDIR)"
	install -d $(BASHDIR)
	install prep/whizzytex $(BASHDIR)
	@echo; echo "## Installing whizzytex.sty in $(LATEXDIR)"
	install -d $(LATEXDIR) && \
	install whizzytex.sty $(LATEXDIR)
