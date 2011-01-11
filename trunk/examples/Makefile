DIRS= basic multiple includes book slides effects 
FILES= $(patsubst %,%/main.dvi,$(DIRS))

all: $(FILES)

.tex.dvi:
	cd $(<D); latex $(<F)

clean:
	rm -f */*.{aux,log,dvi,ans,dview,wiz,waux,fmt,out,nav,snm,vrb,toc}

superclean: clean
	rm -f $(FILES)
	rm -f {.,*}/{*~,.#*,#*#}
	rm -rf */_whizzy_*

.SUFFIXES: .tex .dvi
