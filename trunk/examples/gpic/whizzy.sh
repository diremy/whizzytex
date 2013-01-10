#!/bin/bash

gpicheader () {
  if [ -n "$1" ]
  then 
    echo \
  '\expandafter\ifx\csname SourceFile\endcsname\relax\else\SourceFile{'$1'}\fi'
  fi 
  echo \
  '\expandafter\ifx\csname SetLineno\endcsname\relax\else\SetLineno{0}\fi'
}

gpicprocess () {
sed \
 -e '/^.PE/ {
i\
.PE\
\\Setlineno=
=
d
}' "$1" | gpic -t 
}

gpicmkslice () {
     base=`expr "$1" : "_whizzy_\(.*\).tex"`
     from=_whizzy_$base.new
     to=_whizzy_$base.tex
     src=$base.ltx
     rm -f $to
     gpicheader $src > $to
     gpicprocess $from >> $to
     chmod -w $to
}

gpicmkfile () {
     from="$1"
     case $from in
       *.tex) ;;
       *.ltx) 
          to=`basename $from .ltx`.tex
          src=$from
          rm -f $to
          gpicheader $src  > $to
          gpicprocess $from >> $to
          chmod -w $to
          ;;
     esac
}


MKSLICE=gpicmkslice
MKFILE=gpicmkfile
EXT=.tex
