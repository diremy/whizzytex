;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  WhizzyTeX - a wysiwyg environment for TeX
;;  Copyright (C) 2002 Didier Rémy, INRIA-Rocquencourt
;;  
;;  This library is free software; you can redistribute it and/or
;;  modify it under the terms of the GNU Lesser General Public
;;  License as published by the Free Software Foundation; either
;;  version 2 of the License, or (at your option) any later version.
;;  
;;  This library is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
;;   
;;  See the GNU Lesser General Public License version 2.1 for more
;;  details (enclosed in the file LGPL).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  File whizzytex-init.el (init code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; to be placed in .../site-start.d/ subdirectory of Emacs or Xemacs
;; or included in user's Emacs or XEmacs start files

(autoload 'whizzytex-mode
    "/usr/local/bin/whizzytex/lisp/whizzytex.el" 
    "WhizzyTeX, a minor-mode WYSIWIG environment for LaTeX" t)
