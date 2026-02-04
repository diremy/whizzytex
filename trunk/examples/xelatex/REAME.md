NOTE:

This directory is experimental. 

WhizzyTeX does not currently work with xelatex, since xelatex does not allow
dumping after fonts have been loaded. 

While xelatex.fmt does not preload fonts, most document class, including 
article.cls do and prevent the excecution of \dump, which is at the heart
of WhizzyTeX.

