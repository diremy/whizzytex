include Makefile

version.tex: ../VERSION ../RELEASE
	(echo '\def\release{'`cat ../RELEASE`'}' ; \
	echo '\def\version{'`cat ../VERSION`'}' ) > $@

