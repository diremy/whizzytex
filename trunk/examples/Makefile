DIRS= basic multiple includes slides
FILES= $(patsubst %,%/main.dvi,$(DIRS))

all: $(FILES)

.tex.dvi:
	cd $(<D); latex $(<F)

clean:
	rm -f */*.{aux,log,dvi,dview,wiz,fmt}

superclean: clean
	rm -f *~ */*~
	rm -rf */_whizzy_*

.SUFFIXES: .tex .dvi
