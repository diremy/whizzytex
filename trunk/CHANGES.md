NOT COMMITTED YET (OR EXPERIMENTAL):
====================================

Emacs-mode:


Shell-script:

LaTeX macros:

Installation/Documentation:


SINCE LAST MAJOR RELEASE:
=========================

Emacs-mode:

 - version 1.5.0
 * Fix slave setting for subfiles package and format.
 - version 1.4.0
 - version 1.3.7
 - version 1.3.6
 * Small fixes for Debian
 - version 1.3.5
 * move most temporary output files into _whizzy_<basename>_d/out/
 * mupdf: added entry
 - version 1.3.4
 * fix enumiio <- enumiii
 * changed \rm and \bf for \rmfamily and \bfseries

Shell-script: 

 - version 1.5.0
 - version 1.4.0
 * Fixed whizzytex --formatonly to create subdirs
 - version 1.3.7
 * Fixed configure script
 * Added switch view in llpp (with limited support)
 * Added llpp-syntex file in example/llpp/ for synctex support
 * minimum fixes for the verion v32-66 of llpp previewer
 * small fixes for Debian
 - version 1.3.6
 * Small fixes for debian
 - version 1.3.5
 * move most temporary output files into _whizzy_<basename>_d/out/
 * mupdf: new entry, with specific reloading command, rquires xdotool
 - version 1.3.4

LaTeX macros:

 - version 1.5.0
 * Still missing instrumentation forsubfiles package and format.
 - version 1.4.0
 * Fixed \document for new versions of latex.ltx in textlive 2021
 - version 1.3.7
 - version 1.3.6
 * Small fixes for debian
 * Fixed patch of \begin using etoolbox (now assuming eTeX)
 - version 1.3.5
 * mupdf: dump page info in _whizzy_NAME.mark when cursor mark is inserted
 * Fixed preloading of fonts by deactivating line info on *.fd files.
 - version 1.3.4

Installation/Documentation:

 - versoin 1.4
 - version 1.3.7
 * adding directory ./example/llpp/

OLDER CHANGES:
==============

Emacs-mode:

 - version 1.3.3
 * replaced goto-line by whizzy-goto-line to avoid setting the mark.
  [recommanded by Kevin Ryde]
 - version 1.3.2
 * Added an argument to "reslice" to tell if the cursor is present (for xpdf)
 * Changed <viewlog> to <viewtexlog> fixes strange interactions with emacs
 * Added cursor argument to reslice when the cursor is displayed
 * Small changes in whizzy-show-point (under mark, in commands).
 * comint-output-filter-functions made buffer-local in the process windows
 - version 1.3.1
 * fixed some quotes in configuration script.
 * added \jobname.wel configuration file 
 * added whizzy-autohide-cursor
 * fix section counters with multiple files. 
 * fix case-fold-search to nil in all whizzytex searches. 
 * added a trace of the Whizzy Cursor back into the Emacs buffer. 
 * enable redirection of navigation commands to previewer stdin.
 - version 1.3.0
 * Added backward compatibility of linemode with older versions. 
 - version 1.2.3
 * whizzy-toggle-debug not set whizzy-debug 
 * changed communication from whizzytex back to emacs.
 * added support for -pdf xpdf mode.
 * enter Emacs-debugger on fatal error when called in debug-mode.
 * change whizzy-sit-for for compatibility with Emacs on mac-os-10
 - version 1.2.0 
 * fixed ^ in middle of whizzy-mode-regexp-alist
 * test for the file associated to the buffer already exists.
 * small slices can be automatically enlarged to fit some number of pages
 * does not shrink log during initialization and save it at the end
 * changed names of configuration files whizzy.el 
 * fix a bug in parsing -dvicopy file-configuration. 
 * added whizzy-auto-recompile function to set corresponding variable.
 - version 1.1.3
 * overlays are now variables and can now be customized.
 * changed whizzy-edit API.
 * added -display option.
 - Version 1.1.2
 * whizzy-master is ignored when set to the buffer itself.
 * Revert buffer keeps whizzytex alive (cleaning on failure must be FIXED.)
 * Added prefix-arg 16 to start whizzutex in debug mode. 
 * Removed the use of view-mode as a local-variable!!!
 - Version 1.1.1
 * warn and pop-up interaction window when fails during initialization.
 * added debug variable in emacs and menu entry to toggle it
 * move to the first slice in not already in a slice when mode is turn on
 * fixed (partially?) the bug with the cursor moving abruptly to the end of
   buffer, when input was too fast.
 * added a timer to make the slice always consistent after 2s. 
 * replaceed sit-for by a timer to pop-up the interaction buffer after 2s. 
 * added BIBTEX switching support, to allow use of jbibtex.
 * added per-file hooks
 * fixed/changed parsing of options
 * added parsing of the option -dvicopy
 * recognizes advi driven Next-Slice and Previous-Slice moves 
   (by default, right and left clicks in Upper Left corner of the advi windown)
 - Version 1.1
 * \begin{document} and \end{document} should be preceded by space or newline 
 * WhizzyEdit with multiple files. 
 * Now loop detection when searching for a master-file...
 * TeX-master only used when file is a slave (don't trust auctex).
 * Turn mode off and on around revert-buffer.
 * Turning mode off in the process buffer now (correctly) acts on the master. 
 * searches for master file in latex log files in the current directory.
 * searches for master file in buffers running whizzytex. 
 * join between section and latex counters done in emacs instead of bash
 * macro files can be whizzytex (action is to reformat on save-buffer)
 * now leave write-region-annotate-functions global 
   (should become compatible with new version of x-symbol package).
 * added whizzy-edit to edit (move and resize) tex objects from advi.
 * added detexification so that whizzy-goto-line works in latin mode. 
 * whizzy-goto-line takes surounded words into accoun for better precision
 * renamed -fmt into -format and added -fmt for format extension
 * changed whizzy-setup-manager to give priority to buffer information
 * added a pessimistic version of whizzy-show-point and menu entries
 * made it work with all file extensions but those internally used
 * added slower slice saving option for x-symbol compatibility.
 * fixed whizzy-suppend
 * added whole (document error) in line-mode string.
 * complete rewrite of whizzy-show-position 
 * fixed write-file-config.
 * added -initex and -latex to set INITEX and LATEX
 * fixed overlays of errors.
 * temptative fix of whizzy-write-slice to work with X-symbols mode.
 * added whizzy-key-bindings with two default values for latex or auctex
 - Version 1.00
 * fixed whizzy-read-mode-from-file 
 - Version 1.00-beta
 * Added whizzy-write-configuration to dump file configuration
 * Fixed key bindings in menu
 * Rewrote reading of file configuration.
 * Added whizzy-load-factor to adjust slicing speed.
 * Improved the online documentation (it is now pretty detailed)
 * R�cup�ration d'erreur lorsque le buffer principal est effac� ses esclaves.
 * Corrected setup of multi-file documents
 - Version 1.00-alpha
 * Cleaned up and rewritten for version 1.00-alpha

Shell-script: 

 - version 1.3.3
 * Fixed driver setting
 * Fixed the "okular" previewer mode.
 * Added a "noviewer" predefined viewer for either dvi or pdf modes. 
 - version 1.3.2
 * Do not change page in xpdf reloading when cursor position is not available
 * Changed <viewlog> to <viewtexlog> because fo strange interaction with emacs
 * pdf mode now calls -reload only when the cursor is not displayed. 
 * pdf mode changes latex to pdflatex format
 * Added PDF* shell variables to preconfigurate whizzytex for pdflatex
 * Postdate slice for use in xpdf mode
 * Pass output mode (dvi or pdf) to latex
 * Added quotes in "$INPUT/view.$$" to allow white spaces  in DIRS
 * Wrapped dvicopy to make it atomic.
 - version 1.3.1
 * fixed some quotes in configuration script.
 * added \jobname.wsh configuration file 
 * enable redirection of navigation commands to previewer stdin.
 - version 1.2.3
 * fix configure and checkconfig to allow -initex 'tex -ini'
 * changed communication from whizzytex back to emacs.
 * added support for -pdf xpdf mode.
 * write in .waux and read in .raux to be stable in face of errors
 - version 1.2.0 
 * diplay VERSION number with option -version and command info.
 * allow spaces in directory names (not in the filename itself).
 * changed names of configuration files whizzy.sh 
 * added a flag during initialization, so as to keep debugging information
 * added AUTOCOMPILE and AUTORECOMPILE variables.
 * removed obsolete DOMARKS.
 - version 1.1.3
 * added internal duplex mode if MULTIPLE files can be viewed altogether
 * added -display option 
 - Version 1.1.1
 * warn when fails during initialization
 * keep log files when turn off in debug mode
 * added system and per-user CONFIGFILE support.
 * added BIBTEX switching support, to allow use of jbibtex.
 * support -display option for whizzytex.
 * added the option -dvicopy to postprocess the dvi
 - Version 1.1
 * Replace suicide by cleanquit whenever possible.
 * removed join between section and latex counters (now done in emacs).
 * now start with /bin/sh and calls bash (seach in PATH).
 * renamed FMT into FORMAT and added FMT for format extension.
 * change newslice detection (does not watch other file but the slice)
 * alternative when grep does not recognize -B
 * made it work with all file extensions but those internally used
 * refresh the duplex window if any when full document has been recompiled
 * added checkconfig script
 * added BASH configuration 
 * added INITEX, LATEX, and LATEXFMT variables to enable platex
 * renamed filename.wiz into filename.waux (not deleted on exit).
 * rename .dview extension into .wdvi and filename.wdvi is deleted on exit.
 * renamed auxiliary filename.fmt into _whizzy_filename.fmt (deleted on exit).
 * Fix a typo in read of commands (duplex reformat were not understood)
 - Version 1.00
 - Version 1.00-beta
 - Version 1.00-alpha
 * Cleaned up and rewritten for version 1.00-alpha

LaTeX macros:

 * Fixed driver setting
 - version 1.3.2
 * Desactivated \refstepcounter when changed (cleveref package). Temporary fix.
 * Added \AtEndPreloadaux hook run after preloading of aux files
 * Takes output mode (dvi or pdf) from shell-script
 * Automatically load hyperref in pdflatex mode
 * Pass pdftex driver to hyperref in pdflatex mode
 * inhibited adjustment of enumi* counters
 - version 1.3.0
 * Fix \label to work with hyperref...
 * Experimental auto-adjustment of counters (using \label).
 - version 1.2.3
 * some changes to allow anchors with pdftex driver.
 * fixed the problem with the new hypertex package (\scrollmode). 
 * set default hyperref option to hypertex (not best, but better than nothing)
 * write in .waux and read in .raux to be stable in face of errors
 - version 1.2.0 
 * fixed display of cursor in vmode.
 * small slice can be automatically enlarged to fit some number of pages.
 * changed names of configuration files whizzy.sty
 - version 1.1.3
 * changed whizzy-edit interface
 * \WhizzyInsideEnvironment to change the behavior when the cursor is inside.
 - Version 1.1.1
 * load advi.sty in advi mode
 - Version 1.1
 * added \SourceFile{<NAME>} macro to be used in processed files.
 * made it work with all file extensions but those internally used
 * fixed a bug in use of \everydisplay
 * renamed filename.wiz into filename.waux
 - Version 1.00
 - Version 1.00-beta
 - Version 1.00-alpha
 * Cleaned up and rewritten for version 1.00-alpha

Installation/Documentation:

 - version 1.3.3
 * Fix the example and documentation for use with Okular PDF previewer. 
 - version 1.3.2
 * Some macros for compatibility with XEamcs and version 22.
 * Documentation for whizzy-point-face.
 - version 1.3.1
 * fixed some quotes in configuration script.
 * added \jobname.wsty configuration file 
 * added patches for pgf package and beamer class. 
 * made \WhizzyAdjustCounter not fail if counter is undefined. 
 * fix bug due to writing file names in .aux. 
 - version 1.3.1
 * fixed some quotes in configuration script.
 - version 1.3.0
 * fix in ./configure for 'latex -ini' not to block
 * ./configure default initex to 'latex -ini' if not found.
 * Fixed quotation of command names in script during installation
 * HTML should now be generated with hevea 1.08
 - version 1.2.3
 * Export sources of the documentation
 * Update customozation with -pdf option (and a few changes)
 * timeout option to ./checkconfig (in case fonts need to be rebuilt).
 - version 1.2.0 
 * configuration, customization
 * added a redhat noarch.rpm (spec file provided by Jakuv Narebski)
 * fixed Makefile
 * whizzy-edition: documentation and examples.
 - version 1.1.3
 * MULTIPLE configuration variable and documentation
 * Few small fixes/changes.
 - Version 1.1.1
 * adjusted the manual for initialization
 * add system and per-user CONFIGFILE support.
 * add BIBTEX switching support, to allow use of jbibtex.
 - Version 1.1
 * Clean up the documentation.
 * Replace -KILL by -TERM in checkconfig.
 * renamed manual.info in whizzytex.info
 * Added examples/edit/{main.tex,whizzedit.sty}
 * Change of Manager makefile to call ./configure when changed
 * Rewrote ./configure to work in batch and take command line arguments
 * Reorganized Web page, added FAQ.html
 - Version 1.00
 * Moved URL  to http://pauillac.inria.fr/whizzytex
 * Manager check for compatility of Makefile.config of previous version
 - Version 1.00-beta
 * Improved the manual.tex documentation. 
 * Makefile.config can default to a copy of Makefile.config.in
 * Improved Makefile and configuration script
 * Changer version upgrading (probably incompatible, do this one by hand)
 * Version xxx tar in whizzytex-xxx now untars as whizzytex-xxx/<sources>
 * Makefile for upgrading to new versions. 
 * configuration script that attempts at finding a location for emacs files. 
 - Version 1.00-alpha
 * Makefile for version 1.00-alpha

Last-modified: <2004-10-04 09:48:54 remy>

