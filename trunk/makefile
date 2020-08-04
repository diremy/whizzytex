infoSHELL=bash
LC_CTYPE=C
LANG=C
BIN=$(HOME)/bin
TEX=$(HOME)/lib/tex
# Stable version
RELEASE=1.3.5
# Current version
VERSION=1.3.6
# rpm release version
Release=1
# YAP version -- independant versionning. 
NAME=whizzytex-$(VERSION)
TAG=.VERSION_$(VERSION)
PACKDIR=packdir

WHERE=homepage 

ifeq ($(WHERE), homepage)
  YQUEM=yquem:/home/nas/gallium/remy/public_html/whizzytex
else
  YQUEM=yquem:/net/yquem/infosystems/www/gallium/gallium/whizzytex
endif

# BASEURL=http://gallium.inria.fr/whizzytex/
SCP=scp

RPMNAME=whizzytex-$(VERSION)-$(Release)

SRCFILES=whizzytex whizzytex.el whizzytex-init.el whizzytex.sty

TARSOURCES = $(patsubst %,src/%,$(SRCFILES)) \
	    GPL COPYING CHANGES \
            Makefile Manager Makefile.config.in \
	    byte-compile.el configure.el \
            configure checkconfig

TARPRODUCED =  INSTALL VERSION 

TARDIRS = examples 

TARFILES = $(TARSOURCES) $(TARPRODUCED) $(TARDIRS)

XXXPORTS = CHANGES index.html animation.html \
	   FAQ.html FAQ \
	   doc/whizzytex.dvi  doc/whizzytex.html

# 	   whizzytex-yap-$(YAPVERSION).tgz

EXPORTS = index.html animation.html older.html Announce \
	   emacs.gif activedvi.gif emacs009.gif activedvi009.gif \
	   COPYING GPL INSTALL VERSION RELEASE \
	   $(XXXPORTS) $(NAME).tgz

archive:
	mkdir $@

whizzytex:
	mkdir $@

whatelse: 
	@echo 'make what ? [Export Faq Doc pack xxxport ]'

pack: FILES $(EXPORTS) $(addprefix $(PACKDIR)/, .exists checked whizzytex.elc)

doc/version.tex: RELEASE VERSION
	(echo '\\def\\release{'`cat RELEASE`'}' ; \
	 echo '\\def\\Release{'$(Release)'}' ; \
	 echo '\\def\\version{'`cat VERSION`'}' ; \
	 echo '\\def\\YAPVERSION{'$(YAPVERSION)'}' ) > $@


doc/FILES: doc/manual.tex doc/manual.sty doc/Makefile
	cd doc; make all 

Index: index.html animation.html
	$(SCP) $^ $(YQUEM)

Faq: FAQ.html FAQ 
	$(SCP) $< $(YQUEM)

FAQ: FAQ.html 
	lynx -dump $< > $@

FAQ.html: FAQ.tex doc/version.tex
	hevea -o $@ -fix -exec xxdate.exe $<

index.html: index.htm makefile
	rm -f index.html
	sed \
	 -e 's/@RELEASE@/$(RELEASE)/g' -e 's/@VERSION@/$(VERSION)/g' \
	 -e 's/@Release@/$(Release)/g' \
	 -e 's|href="@|href="|g' \
	 $< > $@

# chmod -w index.html

animation.html: index.html
	sed -e 's/009.gif/.gif/g' \
	    -e 's/animation.html">Start/index.html">Stop/g' \
	    -e 's/animation.html/index.html/g' $< > $@

older.html: makefile archive
	(echo '<html><body><H1>Older versions</H1><ul>'; \
	 for i in $$(cd archive; ls -t whizzytex*); \
	 do echo '<li><a href='"$$i"'><tt>'"$$i"'</tt></a>'; done; \
	 echo '</ul></body></html>') > older.html


emacs.gif: anim/animation.tex anim/animation.sty anim/Makefile
	make -C anim $@
	cp anim/$*{,009}.gif .

activedvi.gif: anim/animation.tex anim/animation.sty anim/Makefile
	make -C anim $@
	cp anim/$*{,009}.gif .

INSTALL.txt: doc/whizzytex.html
	lynx -dump $< | sed -f INSTALL.sed > $@


VERSION: makefile
	test `grep '^ORIGIN=' Manager` = 'ORIGIN=$(VERSION)'
	echo $(RELEASE) > RELEASE
	echo $(VERSION) > $@

FILES: $(TARFILES) doc/FILES makefile 
	touch VERSION $(TAG)
	make smallclean
	(echo FILES; echo $(TAG); \
	 tar zcvf - $(TARFILES) $(shell cat doc/FILES) | tar -tf -) \
	  | grep -v CVS | grep -v '/$$' > $@

$(NAME).tgz: FILES makefile
	mkdir $(NAME)
	tar cf - `cat FILES`| (cd $(NAME) && tar xf -)
	tar zcvf $@ $(NAME)
	rm -rf $(NAME)

# grep -e '^\( *\)\(("-advi[^)]*")\) *\(("-dvi[^)]*"\)) *$$' src/whizzytex.el

$(PACKDIR)/checked: $(PACKDIR)/.exists $(SOURCES) $(NAME).tgz
	@echo ' --- Checking examples'
	cd examples; make >/dev/null
	@echo ' --- Checking src/whizzytex.el'
	grep -e '^\((defvar whizzy-command-name "\)[^"]*\(".*\)$$' \
	   src/whizzytex.el
	test X`sed -n -e \
	        's/^(defconst whizzytex-version "\([^"]*\)" *$$/\1/p' \
	  src/whizzytex.el` = X'$(VERSION)'	   
	@echo ' --- Checking src/whizzytex'
	test X`sed -n -e 's/^VERSION="\([^"]*\)" *$$/\1/p' \
	  src/whizzytex` = X'$(VERSION)'	   
	grep -e '^PACKAGE=[/a-z.][/a-z.]*$$' src/whizzytex
	grep -e '^DVIPS=[a-z][a-z]*$$' src/whizzytex
	@echo ' --- src/whizzytex.sty'
	test X`sed -n -e \
	    's/^\\\\def *\\\\whizzy@version *{\([^}]*\)} *$$/\1/p' \
	  src/whizzytex.sty` = X'$(VERSION)'	   
	@echo ' --- whizzytex.spec'
	test X`sed -n -e 's/^Release:[[:space:]]*\([0-9]*\) *$$/\1/p' \
	  whizzytex.spec` = X'$(Release)'	   
	touch $@

$(PACKDIR)/.exists: 
	mkdir -p $(PACKDIR)
	rm -f $(PACKDIR)/checked
	touch $@

$(PACKDIR)/whizzytex.el: src/whizzytex.el $(PACKDIR) 
	cp $< $@

$(PACKDIR)/whizzytex.elc: $(PACKDIR)/whizzytex.el byte-compile.el
	if which emacs; then \
	echo 'Compiling with emacs'; \
	cd $(PACKDIR); \
	emacs --batch -q -l ../byte-compile.el 2>log && cat log  && \
	if grep -e '\*\*' log; then rm -f ../$@; false; fi; \
	fi
	if which xemacs; then \
	echo 'Compiling with xemacs'; \
	cd $(PACKDIR); \
	xemacs -batch -q -l ../byte-compile.el 2>log && cat log && \
	if grep -e '\*\*' log; then rm -f ../$@; false; fi ; \
	fi

rpm: $(RPMNAME).src.rpm 

# Export: $(EXPORTS) xxxport $(RPMNAME).src.rpm DATE 
# 	$(SCP) $(EXPORTS) $(RPMNAME).src.rpm $(cat doc/FILES) $(YQUEM)
# 	$(SCP) VERSION $(YQUEM)/whizzytex.version
# 	mv $(NAME).tgz archive

Export: $(EXPORTS) xxxport DATE 
	$(SCP) $(EXPORTS) $(cat doc/FILES) $(YQUEM)
	$(SCP) VERSION $(YQUEM)/whizzytex.version
	mv $(NAME).tgz archive

Release: Export 
	cp Announce archive/Announce-$(RELEASE)
	$(SCP) Announce $(YQUEM)

xxxport: $(EXPORTS) pack 
	make NAME=whizzytex-xxx whizzytex-xxx.tgz
	date > DATE
	$(SCP) $(XXXPORTS) `cat doc/FILES` whizzytex-xxx.tgz DATE \
	  $(YQUEM)

smallclean:
	cd doc; $(MAKE) clean
	cd examples; $(MAKE) superclean

clean:: smallclean
	rm -rf doc/{*~,.#*,#*#,*.aux,*.log} doc/_whizzy_manual*
	rm -f FAQ.{aux,log,haux,hlog,toc,htoc}
	rm -rf $(PACKDIR)

superclean:: clean
	rm -f doc/ocaml.html $(TAG) $(NAME).tgz manual.dvi \
	rm FAQ.html FAQ
	rm -f *~ .#* #*# FILES 

# REDHAT=/usr/src/redhat
# RPMINPUTFILES= $(NAME).tgz whizzytex-makefile.patch

# $(RPMNAME).src.rpm: $(RPMNAME).noarch.rpm

# $(RPMNAME).noarch.rpm: $(RPMINPUTFILES)
# 	cp $(RPMINPUTFILES) /usr/src/redhat/SOURCES/
# 	rpmbuild -ba whizzytex.spec
# 	cp \
# 	 $(REDHAT)/SRPMS/$(RPMNAME).src.rpm \
# 	 $(REDHAT)/RPMS/noarch/$(RPMNAME).noarch.rpm \
# 	 .
# 	chown remy $(RPMNAME).*rpm
# 	chgrp formel $(RPMNAME).*rpm


.in.out:
	./configure < $<

.PHONY: Export xxxport pack

.SUFFIXES: .tgz .in .out .htm .tex .html .gif


include Makefile
