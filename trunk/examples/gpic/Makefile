SOURCES = main.ltx subfile.ltx
TEXFILES = $(patsubst %.ltx, %.tex, $(SOURCES))
GPIC=../bin/mkgpic

main.dvi: $(TEXFILES)
	latex main.tex

files: $(TEXFILES)

# to force recompilation even if same date (second is not precise enough)
.force:
_whizzy_%.tex: _whizzy_%.new .force
	$(GPIC) -slice $@

%.tex: %.ltx
	$(GPIC) -file $<

clean:
	rm -f *.{tex,log,aux,dvi}
