;;; whizzytex.el --- WhizzyTeX, a WYSIWIG environment for LaTeX 
;; 
;; Copyright (C) 2001, 2002 INRIA.
;; 
;; Author         : Didier Remy <Didier.Remy@inria.fr>
;; Version        : 1.0a
;; Bug Reports    : whizzytex-bugs@pauillac.inria.fr
;; Web Site       : http://cristal/inria.fr/~remy
;; 
;; WhizzyTeX is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;; 
;; WhizzyTeX is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details 
;; (enclosed in the file GPL).
;; 
;; See the file COPYING enclosed with the distribution.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  File whizzytex.el (Emacs-lisp code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;; Commentary: 
;;
;; WhizzyTeX is a minor Emacs mode for previewing LaTeX while your editing
;;
;; To install whizzytex, your also need its two companion files
;;   
;;   whizzytex             (A bash shell-script)
;;   whizzytex.sty         (A LaTeX macro package)
;;
;; The variable whizzy-command-name should be the relative or full path
;; of the executable shell-script, which should itself contain provide the 
;; full or relative part of whizzytex.sty in its PACKAGE variable.
;;
;; To install whizzytex, then add to your ~/.emacs file:
;;
;;   (autoload 'whizzytex-mode "whizzytex" 
;;        "WhizzyTeX, a WYSIWIG environment for LaTeX" t)
;; 
;; To launch WhizzyTeX, tyoe Esc-x whizzytex-mode
;; This applies only to the current buffer.
;;
;; Some user variable control the setting. 
;; See the documentation for details by typing (once autoloaded)
;; 
;;    Esc-x describe-function whizzytex-mode
;;

;;; Code:

(require 'comint)

;;; Bindings

(defvar whizzytex-mode-hook nil
  "*Hook run when `whizzytex-mode' is turned on  (before setting
default parameters). We recommand the use of `whizzy-suggested-hook'
which will setup some usefull whizzytex bindings. 

You can set this hook by including the following line in your emacs.el:

    (add-hook 'whizzytex-mode-hook (function whizzy-suggested-hook))

This will also include some menu Whizzy menu in the menubar. 

 (Conversely, you can use `whizzy-unset-options-hook' to remove
  unset many default options.)
")

;;; User variables

(defvar whizzy-command-name "whizzytex"
  "*Short or full name of the WhizzyTeX deamon")

(defvar whizzy-view (list "-advi" "advi")
  "*Default previewer mode and command. 

A local value can be specifed in the header of the file. For instance,
the above setting could be obtained by insert the line:

%; whizzy <slicing> <previewer> <command> <options>

amongst the first lines of the file, where:

  <slicing> is either

       paragraph, subsubsection, subsection, section, chapter, document,
       letter, or none (see also `whizzy-mode-regexp-alist')
     
       <slicing> is optional and will be inferred if ommitted
  
Usually, 

  <previewer> is one of -ps, -dvi, -advi, or -master
        it is interpretted by emacs and also passed to the whizzytex script
        (except for master ---see below)

  <command> 
        is only passed to the whizzytex script (not interpreted by emacs)
        this is the command that whizzytex should call to launch the
        previewer (see the manual). Command include the name of the
        previewer as well as its options. It is does not have to be quoted. 
        It extends to the right as must as possible, i.e. ends with the end
        of line or some recognized option. 
        

  <options>

        There are three optional options that if present must appear
        in this order:

     -pre <make>

         This defines a command to be passed to whizzytex that is used
         to preprocess the slice, instead of simply renaming the slice.
         The convention is that WhizzyTeX prepares a slice  BASENAME.new,
         calls <make> BASENAME.tex, and expects <make> to produce a file
         BASENAME.tex

         If the option is ommitted, the slice BASENAME.new is simply
         renamed into BASENAME.tex

     -fmt <name>

         This tells whizzytex to huge <name> instead of latex for 
         building the format. For example hugelatex may be needed 
         for huge files. 

     -duplex

         This tells WhizzyTeX to also launch the previewer on
         the whole document. 

When the file is an auxilliary file input by a master file, 
the master file should run whizzytex and the auxilliary file should set

  <previewer> to -master

  <command> to the name of the master file.
")

(defvar whizzy-slicing-commands
  (list 'set-mark-command)
  "*List of commands that should force a slice, anyway.
   Should remain small for efficiency...")

(defvar whizzy-line t
  "*If true, WhizzyTeX will the current line number, so as to enable 
the previewer (advi) to jump to the corresponding page")
(make-variable-buffer-local 'whizzy-line)

(defvar whizzy-point t
  "*Make point visible (and refresh when not too busy)")
(make-variable-buffer-local 'whizzy-point)

(defvar whizzy-paragraph-regexp "\n *\n *\n"
  "*Regexp for paragraph mode")
(make-variable-buffer-local 'whizzy-paragraph-regexp)

(defvar whizzy-error-report
  (and (functionp 'make-overlay)
       (functionp 'delete-overlay)
       (functionp 'overlay-put))
  "*If true  WhizzyTeX will overlay LaTeX errors")


(defvar whizzy-pop-up-windows nil
  "*Local value of \\[pop-up-windows] for WhizzyTeX. 
  (if set WhizzyTeX can split windows when visiting new buffers).")

(defvar whizzy-auto-visit 'whizzytex
  "*Determine what WhizzyTeX should do when a slace buffer is visited. 

Nil means nothing, 'whizzytex means turn WhizzyTeX mode on, 'ask means ask
using y-or-no before turning on, and t means visit the  buffer, but do
not turn WhizzyTeX mode on.")

(defvar whizzy-auto-raise t
  "*If true WhizzyTeX will raise the frame a WhizzyTeX buffer is visited")

(defvar whizzy-mode-regexp-alist
  (append
   (list (cons 'paragraph whizzy-paragraph-regexp))
   '(
     (letter .  "\\(^\\|%WHIZZY\\)\\\\begin{letter}")
     (slide . "\\(^\\|%WHIZZY\\)\\\\\\(overlays *{?[0-9*]+}? *{[% \t\n]*\\\\\\)?\\(begin *{slide}\\|newslide\\)")
     (subsubsection .  "\\(^\\|%WHIZZY\\)\\\\\\(subsubsection\\|subsection\\|section\\|chapter\\)\\b")
     (subsection .  "\\(^\\|%WHIZZY\\)\\\\\\(subsection\\|section\\|chapter\\)\\b")
     (section .  "\\(^\\|%WHIZZY\\)\\\\\\(section\\|chapter\\)\\b")
     (chapter .  "\\(^\\|%WHIZZY\\)\\\\\\(chapter\\)\\b")
     (document .  "\\(^\\|%WHIZZY\\)\\\\begin{document}\\(.*\n\\)+")
     (none . nil)
     )
   )
  "*An alist of pairs (string . regexp) that defines for each sub-mode
the regexp that separates slices.

If keyword whizzy-paragraph is defined in the header of the current buffer,
it overrides this regexp locally, even if the submode is not paragraph. ")

(defvar whizzy-class-mode-alist
  (list
    (cons "seminar" 'slide) 
    (cons "letter"  'letter)
    (cons "article" 'section)
    (cons "book" 'chapter)
    )
  "Alist mapping latex document slides to WhizzyTeX slicing modes"
)

(defvar whizzy-select-mode-regexp-alist
  (list
    (cons "^ *\\\\begin *{slide}" 'slide )
    (cons "^ *\\\\begin *{letter}" 'letter )
    (cons "^ *\\\\\\(subsubsection\\|subsection\\|section\\|chapter\\)" 'section)
   )
  "Alist selecting modes from regexp. Used to find mode automatically"
)


;; End of user variables

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Xemacs compatibility

(defun whizzy-sit-for (seconds &optional milliseconds display)
  (sit-for seconds milliseconds display))

(if (not (boundp 'running-xemacs)) (defvar running-xemacs nil))
(cond
 (running-xemacs
  (require 'overlay)
  (defun window-buffer-height (&optional window)
    (save-selected-window
      (set-buffer (window-buffer window))
      (count-lines (point-min) (point-max))))
  (defun whizzy-sit-for (seconds &optional milliseconds display)
    (sit-for
     (if milliseconds (+ (float seconds) (/ (float milliseconds) 1000))
       seconds)
     display))
  ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; More variables

(defvar whizzy-file-prefix "_whizzy_")
(defvar whizzy-speed-string "?")
(defvar whizzy-error-string "")
(defvar whizzy-mode-line-string
  (list " Whizzy" 'whizzy-error-string "." 'whizzy-speed-string))


;; A vector of whizzytex parameters, shared between all buffers related to the
;; same session. This variable is made buffer local, but its content is 
;; shared between all related buffers.

(defvar whizzy-status nil)
(make-variable-buffer-local 'whizzy-status)

;; fields of the status vector

(defconst whizzy-master-buffer 1)
(defconst whizzy-active-buffer 2)
(defconst whizzy-process-buffer 3)
(defconst whizzy-process-window 25)
(defconst whizzy-process 13)
(defconst whizzy-dir 15)
(defconst whizzy-input-dir 20)
(defconst whizzy-output-dir 21)
(defconst whizzy-filename 23)
(defconst whizzy-basename 17)
(defconst whizzy-slicename 14)
(defconst whizzy-slaves 4)
(defconst whizzy-slice-start 5)
(defconst whizzy-slice-time 6)
(defconst whizzy-slice-date 26)
(defconst whizzy-slice-error 7)
(defconst whizzy-slicing-mode 18)
(defconst whizzy-view-mode 9)
(defconst whizzy-sections 10)
(defconst whizzy-layers 12)
(defconst whizzy-log-buffer 16)
;; (deffonst whizzy-style 27)


(defconst whizzy-length 30)
(defun whizzy-get (f)
  (if whizzy-status (elt whizzy-status f)
     ;; (error "whizzy-get")
     ))
(defun whizzy-set (f v)
  (if whizzy-status (aset whizzy-status f v)
    (error "whizzy-set: attempting to set fiel %d when status is nil" f)))

(defun whizzy-describe (f)
  (interactive "S")
  (with-output-to-temp-buffer "*Help*"
    (print (whizzy-get f))))
      
;; Tell if buffer is a slave and give its relative name to the master dir

(defvar whizzy-slave nil)
(make-variable-buffer-local 'whizzy-slave)


(defvar whizzy-local-sections nil
  "Sections belonging to the current file")
(make-variable-buffer-local 'whizzy-local-sections)


(defun whizzy-read-marks (&optional arg)
  (if (or (whizzy-get whizzy-sections) arg)
      (save-excursion
        (set-buffer (whizzy-get whizzy-master-buffer))
        (let ((whizzytex-marks) 
              (dirname (whizzy-get whizzy-dir))
              (tmp-buffer))
          (load-file (concat (whizzy-get whizzy-output-dir)
                             "sections"))
          (whizzy-set whizzy-sections whizzytex-marks)
          (while (consp whizzytex-marks)
            (and (setq tmp-buffer
                       (find-buffer-visiting
                        (concat dirname (caar whizzytex-marks))))
                 (set-buffer tmp-buffer)
                 (setq whizzy-local-sections (cdar whizzytex-marks)))
            (setq whizzytex-marks (cdr whizzytex-marks)))
          ))))

(defun whizzy-start-process (args)
  (save-excursion
    (let ((buf (apply 'make-comint
                      (buffer-name)
                      whizzy-command-name
                      nil
                      args))
          (status whizzy-status))
      (whizzy-set whizzy-process-buffer buf)
      (whizzy-set whizzy-process (get-buffer-process buf))
      (save-excursion
        (set-buffer buf)
        (erase-buffer)
        (setq whizzy-status status)
        (setq comint-output-filter-functions
              (list (function whizzy-filter-output)))))))
 
(defun whizzy-clean-shell ()
  (save-excursion
    (if (whizzy-get whizzy-process-buffer)
        (progn
          (set-buffer (whizzy-get whizzy-process-buffer))
          (goto-char (point-max))
          (if (or (> (buffer-size) 10000))
               (re-search-backward "Output written on" (point-min) t)
              (erase-buffer))))))


(make-variable-buffer-local 'write-region-annotate-functions)
(defvar whizzy-write-at-begin-document nil)


(defun whizzy-begin-end ()
  (let ((here (point)))
    (skip-chars-backward " ")
    (skip-chars-backward "\\\\begind" (- (point) 6))
    (or (looking-at "\\\\\\(begin\\|end\\)")
        (not (goto-char here)))))

(defun whizzy-show-position ()
  "Returns the place where to insert the position character."
  (if (eobp) nil
    (save-excursion
      (let ((near (point))
            (bol) (there) (bow) (tmp))
        (beginning-of-line)
        (if (looking-at "\n[ \t]*[^\n \t]")
            (progn (next-line 1) (setq near (point))))
        (setq bol (point))
        (if (or
             (looking-at
             "^ *\\\\\\(subsubsection\\|subsection\\|section\\|chapter\\)")
             ;; this is problematic... / too specific
             (looking-at
              "^ *\\\\\\(Meaning\\)"))
            nil
          (if (and (looking-at "\\\\\\(begin\\|end\\){[A-Za-z][A-Za-z]*}")
                 (< near (match-end 0)))
            (setq there bol))
        (goto-char near)
        (if (and
               (or
               (re-search-backward
                "\\\\\\(index\\|cite\\|begin\\|end\\) *{[^{}]*" bol t)
               (re-search-backward
                "\\\\\\([A-Za-z][A-Za-z]*\\) *\\[[^][]*" bol t))
               (= (match-end 0) near))
              (setq near (match-beginning 0)))
          (goto-char near)
          (if (looking-at "[ \n]")
            (progn
              (skip-chars-backward " ")
              (setq near (point))))
        (if (and (= (skip-chars-backward "}") -1)
                 (looking-at "}[ \t]*\n*[ \t]*{"))
            (setq near (point)))
        (skip-chars-backward "A-Za-z" bol)
        (setq bow (point))
        (if (or (= (skip-chars-backward "\\\\") -1)
                (looking-at "\\\\[A-Za-z]"))
            (setq there (point))
          (goto-char near)
          (setq tmp (skip-chars-forward "A-Za-zéèàêâïùÉÈ"))
          (cond
           ((> tmp 2)
            (if (and (looking-at "}")
                     (goto-char bow)
                     (= (skip-chars-backward "{") -1)
                     (whizzy-begin-end))
                (setq there (point))
              (setq there near)))
           ((looking-at " *[[({]{*")
            (setq there (match-end 0))
            (if (whizzy-begin-end) (setq there (point))))
           ((looking-at " *[])}]")
            (setq there near))
           ;; ((and (= tmp 1) (not (looking-at ".[ \n]")))
           ;;  (setq there (+ near 1)))
           (t
            (setq there near))
           )))
        there))))


(defun whizzy-write-slice (from to &optional local word)
    (if local
        (let ((old write-region-annotate-functions)
              ;; (coding coding-system-for-write)
              )
          (setq write-region-annotate-functions
                (list 'whizzy-write-region-annotate))
          (setq whizzy-write-at-begin-document word)
          (condition-case nil
              (unwind-protect
                  (write-region from to (whizzy-get whizzy-slicename)
                                nil 'ignore)
                (setq write-region-annotate-functions old)
                )
            (quit (message "Quit occured during slicing has been ignored"))
            ))
      (write-region from to (whizzy-get whizzy-slicename) nil 'ignore))
  (whizzy-wakeup))

(defun whizzy-write-region-annotate (start end)
  (let ((empty-lines (count-lines (point-min) start))
        (full-lines (count-lines start (point)))
        (word (whizzy-show-position)))
    (if (and word whizzy-point)
        (setq word
              (list (cons word ""))
              )
      (setq word nil))
    (if (not (numberp whizzy-write-at-begin-document))
        (let ((line
               (if whizzy-line          ; (not whizzy-point)
                   (concat
                    "\\WhizzyLine{"
                    (int-to-string (+ empty-lines full-lines))
                    "}")))
              )
          (append
           (list
            (cons start
                  (concat
                   "\\begin{document}\\WhizzySkip"
                   whizzy-write-at-begin-document
                   (make-string empty-lines 10)
                   (if whizzy-slave
                       (concat "\\WhizzyMaster{" whizzy-slave "}"))
                   "\\WhizzyStart" line)))
           word
           (list (cons end "\n\\end{document}\n")))
          ))
    ))

(defvar whizzy-mode nil)
(make-variable-buffer-local 'whizzy-mode)
(setq minor-mode-alist (cdr minor-mode-alist))
(or (assoc 'whizzy-mode minor-mode-alist)
    (setq minor-mode-alist
          (cons (list 'whizzy-mode whizzy-mode-line-string)
                minor-mode-alist)))


(defun whizzy-call (command)
  (if whizzy-mode
  (let* ((p (whizzy-get whizzy-process))
         (pid (process-id p)))
    (continue-process p pid)
    (process-send-string p (concat command "\n"))
  )))


;; variables for slicing

(defvar whizzy-last-tick 0)
(defvar whizzy-last-saved 0)
(defvar whizzy-last-point 0)
(defvar whizzy-last-slice-begin 0)
(defvar whizzy-last-slice-end 0)
(defvar whizzy-last-layer 0)
(make-variable-buffer-local 'whizzy-last-tick)
(make-variable-buffer-local 'whizzy-last-saved)
(make-variable-buffer-local 'whizzy-last-point)
(make-variable-buffer-local 'whizzy-last-slice-begin)
(make-variable-buffer-local 'whizzy-last-slice-end)
(make-variable-buffer-local 'whizzy-last-layer)

;; regexp beginning a slice
(defvar whizzy-begin nil)
(make-variable-buffer-local 'whizzy-begin)

(defun whizzy-local ()
  (not (equal (whizzy-get whizzy-slicing-mode) 'none)))

(defun whizzy-backward (&optional n)
  (if (re-search-backward whizzy-begin (point-min) t (or n 1))
      (let ((max (match-end 0)))
        (if (re-search-backward whizzy-begin (point-min) 'move)
            (goto-char (match-end 0)))
        (re-search-forward whizzy-begin max t)
        (goto-char (match-beginning 0))
        )))

(defvar whizzy-section-regexp
  "^\\\\\\(subsubsection\\|subsection\\|section\\|chapter\\)[^\n]*$")

(defun whizzy-slice (layer)
  ; adjust the mode info string
  (if (> (whizzy-get whizzy-slice-time) 0)
      (setq whizzy-speed-string
            (int-to-string (/ (whizzy-get whizzy-slice-time) 100))))
  (if (equal (whizzy-get whizzy-slicing-mode) 'none) ; no slice
      (whizzy-write-slice (point-min) (point-max))
    (let ((here (point)) word)
      (if (or (whizzy-backward) ; could find the beginning of the slice
              (and
               (re-search-backward "\\\\begin{document}" (point-min) t)
               (goto-char (match-end 0)))
              (and whizzy-slave
                   (goto-char (point-min))))
          (progn
            (if (looking-at "\\\\begin{document}[ \t\n]*")
                (goto-char (match-end 0)))
            (let ((from (point)) (next (match-end 0)) (line))
              (if (consp whizzy-local-sections)
                  (if (and (looking-at whizzy-section-regexp)
                           (setq line (assoc (match-string 0)
                                             whizzy-local-sections))
                           )
                      (setq word (cdr line))
                    (if (and
                         (re-search-backward whizzy-section-regexp
                                             (point-min) t)
                         (setq line (assoc (match-string 0)
                                           whizzy-local-sections)))
                        (setq word (concat (cdr line) (car line) 
                                           "[...]\\par\\medskip"))
                      )))
              (goto-char next)
              (if (and
                   (or (re-search-forward whizzy-begin (point-max) t)
                       (and whizzy-slave
                            (goto-char (point-max))
                            (re-search-forward "$"))
                       (re-search-forward "\\\\end *{document}" (point-max) t))
                   (goto-char (match-beginning 0)))
                  (let ((to (point)))
                    (goto-char here)
                    (setq whizzy-last-slice-begin from)
                    (setq whizzy-last-slice-end to)
                    (setq whizzy-last-point here)
                    (whizzy-move-slice-overlays)
                    (if layer
                        (setq word 
                              (concat "\\WhizzySlide[" layer "]{"
                                      (int-to-string
                                       (count-lines (point-min) here))
                                      "}")))
                    (setq whizzy-last-layer layer)
                    (whizzy-write-slice from to t word)))
              ))
        (goto-char here)
        ))
    ))

(defun whizzy-current-time ()
  (let ((time (current-time)))
     (+ (* (mod (cadr time) 1000) 1000)
                  (/ (cadr (cdr time)) 1000))))

(defun whizzy-set-time (arg)
  (let* ((this (whizzy-current-time))
         (start (whizzy-get whizzy-slice-start))
         )
    (if arg
        (if (= start 0) nil
          (whizzy-set whizzy-slice-start 0)
          (whizzy-set whizzy-slice-time (- this start))
          ) 
      (if (= start 0)
          (whizzy-set whizzy-slice-start this)
        (message "Inconsistent time"))
      )))

(defun whizzy-wakeup ()
  (let* ((p (whizzy-get whizzy-process))
         (s (process-status p))
         (pid (process-id p)))
    (whizzy-set whizzy-slice-date (whizzy-current-time))
    (if (equal s 'stop) (continue-process p pid))
    (comint-send-string p "\n")
    ))

(defun whizzy-kill (&optional arg)
  (let* ((buf (whizzy-get whizzy-process-buffer))
         (p (whizzy-get whizzy-process))
         (s (process-status p))
         (pid (process-id p)))
    (if arg
        (progn
          (shell-command
             (concat whizzy-command-name " -kill "
                     (whizzy-get whizzy-filename)
                     "2>/dev/null"))
          (kill-buffer buf)) 
      (if (equal s 'exit) nil
        (signal-process pid 'SIGQUIT)
        ;; (if (equal (process-status p) 'exit) nil (signal-process pid 'SIGKILL))
          ))))

(defun whizzy-suspend (&optional arg)
  "Suspend or resume slicing in the current buffer in WhizzTeX mode
depended on numeric value of ARG.

This leaves WhizzyTeX running and can be useful to do a sequence of editing 
while slicing could be distracting or annoying."
  (interactive "P")
  (cond
   ((null whizzy-mode)
    (error "WhizzyTeX is not on"))
   ((or (and arg (> (prefix-numeric-value arg) 1))
             (equal whizzy-mode t))
    (remove-hook  'post-command-hook 'whizzy-observe-changes t)
    (setq whizzy-mode 'suspended))
   ((equal whizzy-mode 'suspended)
    (add-hook  'post-command-hook 'whizzy-observe-changes t)
    (setq whizzy-mode t))
   (t
    (error "Unknown whizzy-mode %S" whizzy-mode))))

(defvar whizzy-load-factor 0.5
  "Roughtly, this will make WhizzyTeX use that factor of the available
CPU time. Decreasing this will slice slower and let emacs 
or other processus be more responsive.")

(defun whizzy-wait (miliseconds)
  (let ((delay (round (/ miliseconds whizzy-load-factor))))
    (if (> (- (whizzy-current-time) (whizzy-get whizzy-slice-date))
           delay) t
      (while (and
              (< (whizzy-get whizzy-slice-time) 0)
              (whizzy-sit-for 0 delay)))
      (whizzy-sit-for 0 delay))
    ))

(defun whizzy-duplex ()
  "Launch another previewer on the whole document"
  (interactive)
  (whizzy-call "duplex"))

(defun whizzy-observe-changes (&optional ignore-check)
  (if executing-kbd-macro t
    (if (or whizzy-mode ignore-check)
        (let ((tick (buffer-modified-tick))
              (ticks (- (buffer-modified-tick) whizzy-last-tick))
              (pos (point)) (layer) (tmp) 
              (error t))
          (unwind-protect
              (progn
                (if (or
                     (and
                      (or (if (or (/= ticks 0)
                                  (not (equal (whizzy-get whizzy-active-buffer)
                                              (current-buffer))))
                              t
                            (if (or (buffer-modified-p)
                                    (= tick whizzy-last-saved))
                                nil
                              (setq whizzy-last-saved tick)
                              (whizzy-wakeup) ; rerun same slice
                              nil))
                          (and (whizzy-local)
                               (or 
                                (< pos whizzy-last-slice-begin)
                                (> pos whizzy-last-slice-end)))
                          (and whizzy-layers
                               (progn
                                 (beginning-of-line)
                                 (setq tmp (point))
                                 (goto-char pos)
                                 (if (re-search-backward
                                      "\\\\overlay *{?\\([0-9*]\\)" tmp t)
                                     (setq layer (match-string 1)))
                                 (goto-char pos)
                                 (not (equal layer whizzy-last-layer))))
                          (or (member this-command whizzy-slicing-commands))
                          )
                      (or (whizzy-wait
                               (/ (* (if (whizzy-get whizzy-slice-error) 4 2)
                                     (whizzy-get whizzy-slice-time))
                                  (+ ticks 1))) 
                          (> ticks 10)))
                     (and whizzy-point
                          (not (equal (point) whizzy-last-point))
                          (whizzy-wait
                           (* (whizzy-get whizzy-slice-time) 4))))
                    (progn
                      (whizzy-set whizzy-active-buffer (current-buffer))
                      (whizzy-slice layer)
                      (setq whizzy-last-tick tick)
                      ))
                (setq error nil))
            (if (and error whizzy-mode)
                (progn
                  (message "*** Fatal Error while slicing. Mode turned off")
                  (whizzy-mode-off)))
            ))
      (whizzy-mode-off))))



(defun whizzytex-mode (&optional arg)
  "If ARG is null, it switches whizzytex mode. 

Otherwise, according to the numeric value of ARG it turns mode off (< 0)
or on (>= 0). 

Turning the mode on assigns (or reassigns) default values to parameters 
whenever possible, reading the top of the file for possible  local values
(see `whizzy-view'). 

By default, the user is only asked when some parameters are missing and 
cannot be assigned default values. 

However, if ARG is 4, the user is asked interactively to confirm/change 
the main parameters. 

When the mode is turn on explicitly (with prefix arg) while it is already on, 
then the mode is sucessively first turned off then on.

The command also evaluates `whizzytex-mode-hook'." 

  (interactive "P")
  (let ((new-mode 
          (if (null arg)
              (not whizzy-mode)
              (>= (prefix-numeric-value arg) 0))))
    (if (and whizzy-mode
             (or (not new-mode) (not (null arg))))
        (progn (whizzy-mode-off) (whizzy-sit-for 1)))
    (if (and new-mode (not whizzy-mode))
        (whizzy-mode-on (prefix-numeric-value arg))))
  whizzy-mode)

(defvar whizzy-mode-map nil 
  "*Keymap used in `whizzytex-mode'")

(defun whizzy-mode-on (&optional query)
  (if whizzy-mode nil
    (or whizzy-status (setq whizzy-status (make-vector whizzy-length nil)))
    (if (not (whizzy-setup (= query 4)))
        (progn
          (message "Setup failed. Turning mode off")
          (whizzy-mode-off))
      (if (and (buffer-modified-p)
                (y-or-n-p "Save buffer? "))
          (save-buffer))
      (whizzy-create-slice-overlays)
      (make-local-hook 'post-command-hook)
      (make-local-hook 'kill-buffer-hook)
      (add-hook 'post-command-hook 'whizzy-observe-changes t t)
      (add-hook 'kill-buffer-hook 'whizzy-mode-off t t)
      (if whizzy-slave
          (let ((marks) (filename buffer-file-name) (basename))
            (whizzy-set whizzy-slaves
                        (cons (current-buffer) (whizzy-get whizzy-slaves)))
            (setq basename
                  (concat 
                   (regexp-quote
                    (file-name-directory (buffer-file-name)))
                   "\\(.*\\)"))
            (if (string-match basename filename)
                (setq marks
                      (assoc (match-string 1 filename)
                             (whizzy-get whizzy-sections)))
              )
            (if (and (consp marks) (cdr marks))
                (setq whizzy-local-sections (cdr marks))))
        (whizzy-set whizzy-master-buffer (current-buffer))
        (let* ((filename (file-name-nondirectory
                          (or buffer-file-name
                              (error "Buffer has no associated file name"))))
               (dir (file-name-directory buffer-file-name))
               (basename (concat whizzy-file-prefix
                                 (file-name-sans-extension filename)))
               (subdir (concat dir basename "/"))
               (input (concat subdir "input/"))
               (output (concat subdir "output/"))
               (slicename (concat input basename ".new"))
               (logname (concat output "log"))
               )
        (whizzy-set whizzy-slicename slicename)
        (whizzy-set whizzy-filename filename)
        (whizzy-set whizzy-basename basename)
        (whizzy-set whizzy-dir dir)
        (whizzy-set whizzy-input-dir input)
        (whizzy-set whizzy-output-dir output)
        (whizzy-set whizzy-log-buffer logname)
        (if (let* ((p (whizzy-get whizzy-process))
                   (s (and p (process-status p))))
              (or (equal s 'run) (equal s 'stop)))
            (whizzy-kill t))
        ;; file-accessible-directory-p ?
        (or (file-exists-p subdir) (make-directory subdir))
        (or (file-exists-p output) (make-directory output))
        (or (file-exists-p input) (make-directory input))
        ;; do we want this? YYY
        (whizzy-set whizzy-slaves nil)
        (let ((arg
               (append                             
                (if (equal (whizzy-get whizzy-slicing-mode) 'slide) nil
                  (list "-marks"))
                (append (whizzy-get whizzy-view-mode) (list filename))
                )))
          (whizzy-start-process arg))

        ))
      (whizzy-set whizzy-slice-date (whizzy-current-time))
      (whizzy-set whizzy-slice-start 0)
      (whizzy-set whizzy-slice-time 0)
      (whizzy-observe-changes t)
      (setq whizzy-last-tick -1)
                                        ; (use-local-map whizzy-mode-map)
      (setq whizzy-mode t)
      (whizzy-set whizzy-slice-error nil)
       ; (if (not (member (current-buffer) whizzy-buffers))
       ;     (setq whizzy-buffers (cons (current-buffer) whizzy-buffers)))
      )))

(defun whizzy-mode-off (&optional arg)
  "Turn WhizzyTeX mode off"
  (interactive "p")
  (if (not whizzy-mode) nil
    (remove-hook  'post-command-hook 'whizzy-observe-changes t)
    (remove-hook  'kill-buffer-hook 'whizzy-mode-off t)
    (whizzy-delete-slice-overlays)
    (whizzy-delete-error-overlay)
    (if whizzy-slave
        (whizzy-set whizzy-slaves (cdr (whizzy-get whizzy-slaves)))
      (whizzy-kill)
      (while (consp (whizzy-get whizzy-slaves))
        (let ((buf (car (whizzy-get whizzy-slaves))))
          (if (buffer-live-p buf)
              (save-excursion (set-buffer buf) (whizzy-mode-off))))
      ))
    (setq whizzy-mode nil)))


(defun whizzy-auto-mode ()
  (save-excursion
    (goto-char (point-min))
    (let ((mode nil)
          (regexp whizzy-select-mode-regexp-alist))
      (if (re-search-forward
           "^ *\\\\documentclass[^{}\n]*{\\([a-zA-Z]+\\)}"
           (point-max) t)
          (setq mode (assoc (match-string 1) whizzy-class-mode-alist)))
      (if (consp mode)
          (cdr mode)
        (while
            (and (not mode) (consp regexp))
          (if (re-search-forward (car (car regexp)) (point-max) t)
              (setq mode (cdr (car regexp)))
            (setq regexp (cdr regexp))))
        (or mode 'document)
        ))))

(defun whizzy-setup-mode (mode)
  "Adjust local variables according to mode"
  (setq whizzy-begin (cdr (assoc mode whizzy-mode-regexp-alist)))
  (cond
   ((null mode)
    (error "Mode should be a non-nil atom"))

   ((member mode '(subsubsection subsection section chapter document none))
    (whizzy-set whizzy-sections (or (whizzy-get whizzy-sections) t)))

   ((equal mode 'paragraph)
    (whizzy-set whizzy-sections (or (whizzy-get whizzy-sections) t))
    (let ((str (whizzy-string-from-file "whizzy-paragraph" 1)))
      (setq whizzy-begin
            (or (and str  (car (read-from-string str)))
                (cdr (assoc mode whizzy-mode-regexp-alist))
                whizzy-begin)))
    )

   ((equal mode 'slide)
    (whizzy-set whizzy-sections nil)
    (save-excursion
      (goto-char (point-min))
      (if (or (re-search-forward
               "^\\\\documentclass *\\[\\([^]{}\n]*,\\)*semlayer\\(,[^]{}\n]*\\)*\\]"
               (point-max) t)
              (re-search-forward "\\\\overlay *{?[0-9*]" (point-max) t))
          (whizzy-set whizzy-layers t))))
   ((equal mode 'letter)
    (whizzy-set whizzy-sections nil))
   (t
    (error "Ill-formed mode"))
   )
  (if (and (null whizzy-begin) (not (equal mode 'none)))
      (error "Ill-formed slicing mode or incomplete whizzy-mode-regexp-alist"))
  (whizzy-set whizzy-slicing-mode mode)
  )

(defun whizzy-read-mode (&optional default)
  (interactive)
  (let* ((table
          (mapcar (lambda (x) (cons (symbol-name (car x)) (car x)))
                  whizzy-mode-regexp-alist))
         (mode
          (completing-read (format "Mode [%S] : " default) table nil t nil))
         (elem)
         )
    (if (setq elem (and mode (assoc mode table))) (cdr elem) default)))

(defun whizzy-change-mode (&optional arg)
  "If ARG is a symbol, set mode to to ARG. 
If ARG is null read mode interactively
Otherwise, if set mode to section unit acording to the prefix value of ARG:
6, 7, and 8 set mode to document, paragraph and none. 
0 and 9 behaves as -1 and 1.
Positive (negative) values of ARG widen (narrow) slice by as ARG steps."
  (interactive "P")
  (let ((p (prefix-numeric-value arg))
        (m (whizzy-get whizzy-slicing-mode))
        (mode) (modes))
    (if (= p 0) (setq p -1)
      (if (= p 9) (setq p 1)))
    (setq mode
          (cond
           ((null arg) (whizzy-read-mode m))
           ((symbolp arg) arg)
           ((= p 8) 'none)
           ((= p 7) 'paragraph)
           ((= p 6) 'document)
           ((and (> p -5) (< p 5) m)
            (setq modes (nthcdr 3 (mapcar 'car whizzy-mode-regexp-alist)))
            (if (> p 0) (nth p (member m modes))
              (nth (- 0 p) (member m (reverse modes)))))
           (t (whizzy-read-mode m))
           ))
      (message "Setting mode to: %S" (or mode m))
      (if (not mode) nil
        (if (not (assoc mode whizzy-mode-regexp-alist))
            (error "Ill formed mode")
          (whizzy-setup-mode mode)
          (whizzy-delete-slice-overlays)
          (setq whizzy-last-slice-begin 0)
          (setq whizzy-last-slice-end 0)
          (setq whizzy-last-tick -1)
          ))))

(defun whizzy-read-mode-from-file ()
  (let* ((mode-string
          (whizzy-string-from-file "whizzy" 1 "\\([^ \n---]+\\)[^\n]*"))
         (mode-begin (and mode-string (match-beginning 1)))
         (mode-end (and mode-string (match-end 1)))
         (mode))
    (if mode-string
        (if (setq mode
                  (assoc mode-string
                         (mapcar (lambda (x) (cons (symbol-name (car x))
                                                   (car x)))
                                 whizzy-mode-regexp-alist)))
            (setq mode (cdr mode))
          (goto-char mode-begin)
          (set-mark mode-end)
          (error
           (concat
            "Slicing mode ``" mode-string
            "'' is not valid. Use: document, section, slide, or paragraph")))
      (setq mode (whizzy-auto-mode)))
    mode))
    
(defun whizzy-setup-view-mode (mode)
  (whizzy-set whizzy-view-mode mode)
  (save-excursion
    (goto-char (point-min))
    (if (not (re-search-forward
              "^[^%\n]*\\\\begin{document}" (point-max) t))
        (if (re-search-forward
             "^[^%\n]*\\(\\\\begin *{document}\\)"
             (point-max) t)
            (error (concat "The expression ``" (match-string 1)
                           "'' should not contain any white space"))
          (error "Missing \\begin{document}"))))
  )

(defun whizzy-basename (name &optional ext)
  (if (string-match (concat "\\(.*\\)" (regexp-quote (or ext ".tex"))) name)
        (match-string 1 name)
      name))

(defun whizzy-unquote (string)
  (if (string-match "\"\\(.*\\)\"" string)
      (match-string 1 string)
    string))
                          
(defun whizzy-read-view-from-file ()
    (let ((view (whizzy-string-from-file
                 "whizzy" 1
                 "[^ \n-]*[a-z]* *\\(-[advips][^\n]*[^ \n]*\\) *"
                 ))
          (r) (s))
      (and view
           (string-match "^\\([^ ]+\\) +\\(.*\\)$" view)
           (progn
             (setq r (list (match-string 1 view)))
             (setq s (match-string 2 view))
             (if (string-match "\\(.*[^ \n]\\) +-pre +\\(.*\\)" s)
                 (progn
                   (setq r (cons "-pre" (cons (match-string 1 s) r)))
                   (setq s (match-string 2 s))))
             (if (string-match "\\(.*[^ \n]\\) +-fmt +\\(.*\\)" s)
                 (progn
                   (setq r (cons "-fmt" (cons (match-string 1 s) r)))
                   (setq s (match-string 2 s))))
             (if (string-match "\\(.*[^ \n]\\) +-duplex" s)
                 (setq r (cons "-duplex" (cons (match-string 1 s) r)))
               (setq r (cons s r)))
             (reverse (mapcar 'whizzy-unquote r)))
           )))
  

(defun whizzy-setup (&optional query)
  (run-hooks 'whizzytex-mode-hook)
  (let ((slicing (whizzy-get whizzy-slicing-mode))
        (view (whizzy-get whizzy-view-mode)))
    (or
     ;; do not reset if query or already bound
     (and query slicing)
     ;; reset otherwise
     (setq slicing (whizzy-read-mode-from-file)))
    (if query (setq slicing (whizzy-read-mode slicing)))
    (whizzy-setup-mode slicing)
    (or
     ;; do not reset if query and already locally bound
     (and query view)
     ;; attempt to reset otherwise
     (setq view (or (whizzy-read-view-from-file) view))
     ;; no local binding: do not query if already bound
     view
     ;; file is mastered and master is known 
     ;; shoud not set view-mode, who cases. 
     (and whizzy-slave
          (setq view
                (concat "-master "
                        (buffer-file-name
                         (whizzy-get whizzy-master-buffer)))))
     ;; otherwise query
     (setq query t))
    (if query
        (setq view
              (let ((view-pair (or view whizzy-view)))
                (list
                 (read-string "Viewer type: " (car view-pair))
                 (read-string "Viewer command: " (cadr view-pair))
                 ))))
    ;; view is optional, whizzy-view has a default-value
    ;; (there should always be a default value)
    (if (and (listp view) (> (length view) 1))
        (let ((type (car view))
              ;;(command (cadr view))
              )
          (cond
           ((string-equal "-default" type)
            (if (whizzy-get 'whizzy-view-mode)
                (setq view (whizzy-get whizzy-view-mode))
              (setq view whizzy-view)))
           ((member type '("-ps" "-dvi" "-advi"))
            (whizzy-setup-view-mode type))
           ((equal type "-master")
            ;;(whizzy-setup-slave command)
            )
           (t
            (error (concat "Viewer type " type
                           " should be either -ps, -dvi, or -dvi")))
           ))
      (error
       "Viewer command should match be of the form  TYPE ARGUMENT"))
    (if (and view slicing)
        (progn 
          (whizzy-set whizzy-view-mode view)
          (whizzy-set whizzy-slicing-mode slicing)
          )
      )
    t))

;; to read file-dependend configuration parameters

(defun whizzy-string-from-file (keyword count &optional regexp)
  (save-excursion
    (beginning-of-buffer)
    (setq regexp (or regexp "\\([^\n]*[^ \n]\\)"))
    (if (and
         keyword
         (re-search-forward
          (concat "^%; *" keyword " +" regexp " *$")
          400 'move count))
        (if (match-beginning 2) (match-string 2) (match-string 1))
        
      nil
      )))


; (defun whizzy-start-shell ()
;   (require 'shell)
;   (save-excursion
;     (set-buffer (make-comint "whizzy-shell" "bash" nil "-v"))
;     (if (zerop (buffer-size))
;         (sleep-for 1))))

(defun whizzy-recenter-output-buffer (linenum)
  "Redisplay buffer of whizzytex job output so that most recent output 
can be seen. The last line of the buffer is displayed on line LINE of 
the window, or centered if LINE is nil."
  (interactive "P")
  (let ((tex-shell (whizzy-get whizzy-process-buffer))
        (old-buffer (current-buffer)))
    (if (null tex-shell)
        (message "No WhizzyTeX output buffer")
      (pop-to-buffer tex-shell)
      (bury-buffer tex-shell)
      (goto-char (point-max))
      (recenter (if linenum
                    (prefix-numeric-value linenum)
                  (/ (window-height) 2)))
      (pop-to-buffer old-buffer)
      )))


;;; errors

(defvar whizzy-latex-error-regexp
  "^\\(! Missing \\|! Undefined \\|! LaTeX Error:\\|Runaway argument?\\)")

(defun whizzy-check-errors ()
  (interactive "p")
  (let ((source-buffer (or (whizzy-get whizzy-active-buffer) (current-buffer)))
        (shell-buffer (whizzy-get whizzy-process-buffer))
        (error-begin) (error-end) (line-string)
        (shell-moveto))
    (set-buffer shell-buffer)
    (goto-char (point-max))
    (or (window-live-p (whizzy-get whizzy-process-window))
        (set-mark (point-min)))
    (re-search-backward "<Recompilation failed>" (mark) 'move)
    (delete-region (mark) (max (mark) (- (point) 14)))
    (if (re-search-forward
         "^l\\.\\([1-9][0-9]*\\) \\([^\n]*\\)" (point-max) 'move)
        (progn
          (setq error-begin (string-to-int (match-string 1)))
          (setq line-string
                (buffer-substring
                 (max (match-beginning 2) (- (match-end 2) 36))
                 (match-end 2)))
          (if (re-search-backward whizzy-latex-error-regexp
                                  (point-min) t)
              (setq shell-moveto (match-beginning 0))
            (setq shell-moveto 0))
          ))
    (if shell-moveto (unwind-protect (goto-char shell-moveto)))
    (if (not error-begin)
        (whizzy-delete-error-overlay)
      (set-buffer source-buffer)
      (let ((here (point)))
        (unwind-protect
            (progn
              (goto-line error-begin)
              (beginning-of-line)
              (setq error-begin (point))
              (end-of-line)
              (if (search-backward line-string (- (point) 200) t)
                  (progn
                    (setq error-begin (match-beginning 0))
                    (setq error-end (match-end 0)))
                (setq error-end (point)))
              (whizzy-overlay-region
               error-begin
               (if (= 0 whizzy-last-slice-end)
                   (max error-end (+ error-begin 1))
                 (min (max error-end (+ error-begin 1))
                      whizzy-last-slice-end)))
              )
          (goto-char here))
        ))))

;; the whizzy-shell-buffer is shared between several processes. 
;; it is always set to the buffer that saved the most recent slice. 
;; however, occasionally, another concurrent process could report the error 
;; to the wrong buffer. 
;; this could be fixed by echoing the name of the file in the output buffer, 
;; or by using a different buffer for each process.

;; if overlays do not currently work in xemacs. 
;; use the unset options hook and ignore compilation messages.

(defvar whizzy-error-overlay nil)
(make-variable-buffer-local 'whizzy-error-overlay)
(defun whizzy-delete-error-overlay ()
  (if whizzy-error-overlay (delete-overlay  whizzy-error-overlay)))
                        
(make-face 'whizzy-error-face)
(set-face-background 'whizzy-error-face "Khaki")

(defun whizzy-overlay-region (beg end)
  (if (and (< beg end) (< end (point-max)))
      (progn
        (if  (not whizzy-error-overlay)
          (setq whizzy-error-overlay (make-overlay 1 1)))
        (overlay-put whizzy-error-overlay 'face 'whizzy-error-face)
        (move-overlay whizzy-error-overlay beg end (current-buffer))
        )))


(defun whizzy-show-wdiff (arg)
  (if (string-match 
       "\\([0-9]+\\)\\([ac]\\).* Word \\([0-9]+\\)\\([ac]\\).*: \\([^\n]*\\)"
       arg)
      (let ((line
             (+ (string-to-int (match-string 1 arg))
                (if (equal (match-string 2 arg) "a") 1 0)))
            (word
             (- (string-to-int (match-string 3 arg))
                (if (equal (match-string 4 arg) "a") 0 1)))
            (words (match-string 5 arg)))

        (save-excursion
          (goto-line line)
          (if (or (<= (point) whizzy-last-slice-begin)
                  (>= (point) whizzy-last-slice-end))
              nil
            (beginning-of-line)
            (if (re-search-forward "[ \n]+" whizzy-last-slice-end t word)
                (progn
                  (skip-chars-backward "[ \n]" whizzy-last-slice-begin)
                  (let ((list-words  (split-string words "[ ]")) (beg (point)))
                    (while
                        (and (consp list-words)
                             (skip-chars-forward "[ \n]")
                             (looking-at (regexp-quote (car list-words))))
                      (goto-char (match-end 0))
                      (setq list-words (cdr list-words)))
                    (skip-chars-forward "[ \n]" whizzy-last-slice-end)
                    (whizzy-overlay-region beg (point))
                    ))
              )))
        )))

(defun whizzy-show-interaction (&optional arg)
  "Display whizzytex process buffer"
  (interactive "P")
  (if (or whizzy-mode (whizzy-get whizzy-active-buffer)) ; 
      (let* ((buf (current-buffer))
             (shell  (whizzy-get whizzy-process-buffer))
             (window (whizzy-get whizzy-process-window))
             (window-alive
              (and window
                   (window-live-p window)
                   (equal (window-buffer window) shell)))
             (hide (if (null arg) window-alive
                     (= (prefix-numeric-value arg) 0)))
             (height (window-height))
             (resize))
        (if (and window-alive
                 (or (equal (minibuffer-window) window)
                     (equal (next-window window) window)))
            (whizzy-set whizzy-process-window nil)
          (if hide
              (if window-alive
                  (progn
                    (delete-window window)
                    (bury-buffer shell)
                    (whizzy-set whizzy-process-window nil)))
            (if (equal buf (whizzy-get whizzy-active-buffer))
                (save-selected-window
                  (if window-alive (select-window window)
                    (setq height (* (/ height 3) 2))
                    (split-window-vertically  height)
                    (select-window (next-window))
                    (switch-to-buffer shell t)
                    )
                  (setq window (selected-window))
                  (setq resize
                        (- (window-height)
                           (max window-min-height
                                (min (window-buffer-height window)
                                     (/ (+ (window-height) height) 3)))))
                  (select-window (previous-window))
                  (enlarge-window resize)
                  ))
            (whizzy-set whizzy-process-window window))
          )
        )))

(defvar whizzy-auto-show-output t
  "*When true the shell output buffer will appear and disappear 
automatically, according to errors")
(defun whizzy-auto-show (arg)
  (if (and whizzy-auto-show-output
           (or (= arg 0)
               (or (and running-xemacs
                        (= whizzy-last-tick (buffer-modified-tick)))
                   (and (whizzy-sit-for 2)
                        (whizzy-sit-for 2))
                   ))
           (or (window-live-p (whizzy-get whizzy-process-window))
               (not (= arg 0)))
           )
      (whizzy-show-interaction arg)))

(defun whizzy-goto-line (s)
  (if (string-match
"\#line \\([0-9][0-9]*\\), \\([0-9][0-9]*\\) <<\\(.*\\)>><<\\(.*\\)>> \\([^ \t\n]*\\)"
       s)
      (let ((buffer (whizzy-get whizzy-active-buffer))
            (line (string-to-int (match-string 1 s)))
            (last (string-to-int (match-string 2 s)))
            (before (match-string 3 s))
            (after (match-string 4 s))
            (file (match-string 5 s))
            (word) (bound) (stop) (dest-buffer) (fullname)
            )
        (if (equal file "") (setq file nil))
        (if (and (> line last) (/= last 0))
            nil
          (set-buffer buffer)
          (and file
               (setq fullname
                     (concat (whizzy-get whizzy-dir)
                             (whizzy-basename file) ".tex"))
               (or (setq dest-buffer (find-buffer-visiting fullname))
                   (and (or (and (equal whizzy-auto-visit 'ask)
                                 (y-or-n-p
                                  (format "Visit file %s? " fullname)))
                            whizzy-auto-visit)
                        (or (setq dest-buffer (find-file-noselect fullname))
                            (progn
                              (message "File %s does not exits" fullname)
                              (setq stop t)
                              nil))
                        (let ((status whizzy-status))
                          (save-excursion
                            (set-buffer dest-buffer)
                            (setq whizzy-status status)
                            (setq whizzy-slave file)
                            ))))
               (or (minibuffer-window-active-p (minibuffer-window))
                   (let ((temp pop-up-windows))
                     (setq pop-up-windows whizzy-pop-up-windows)
                     (pop-to-buffer dest-buffer)
                     (setq pop-up-windows temp)
                     (if whizzy-auto-raise (raise-frame))
                     t
                     )
                   )
               (progn
                 (set-buffer dest-buffer)
                 (or whizzy-mode
                     (and whizzy-slave
                          (if (equal whizzy-auto-visit 'whizzytex)
                              (whizzytex-mode)
                            (message
                             (substitute-command-keys
                              "Type \\[whizzytex-mode] to whizzytex this file"
                              )))))))
          (if stop nil
            (setq word
                  (concat "[^A-Za-z0-9]\\(" (regexp-quote before)
                          "\\)\\(" (regexp-quote after)
                          "\\)[^A-Za-z0-9]"))
            (let ((here (point)))
              (cond
               ((> last 0)
                (goto-line line) (beginning-of-line) (setq bound (point))
                (goto-line last) (end-of-line)
                (if (re-search-backward word bound t)
                  (goto-char (match-end 1))
                  (if (re-search-backward
                       (concat "\\(" word "\\|" "\n\n\\)")
                       (max 0 (- bound 1000)) t)
                      (goto-char
                       (if (looking-at word)  (match-end 1) here))
                  (goto-char here))))
               ((> line 0)
                (if (= last 0) (setq bound (point-max))
                  (goto-line last) (end-of-line) (setq bound (point)))
                (goto-line line) (beginning-of-line)
                (if (not (re-search-forward word bound t))
                    (goto-char here)
                  (goto-char (match-end 1)))
                )
               (t))
              (whizzy-observe-changes))
            )))
    ))


(defun whizzy-error (error &optional clean)
  (let* ((old (whizzy-get whizzy-slice-error))
         (new (cond
               ((null old) (if clean nil error))
               ((not clean)
                (if (or (equal error 'fmt) (equal old 'fmt)) 'fmt error))
               ((equal old 'tex) (if (equal error 'tex) nil old))
               ((equal old 'fmt) (if (equal error 'fmt) 'tex old)))))
    (if (equal new old) nil
      (whizzy-set whizzy-slice-error new)
      (setq whizzy-error-string
            (if new (concat "-" (symbol-name new)) "")))
    ))
        
(defun whizzy-filter-output (s)
  (if whizzy-error-report
      (cond
       ((string-match "<Compilation succeeded>" s)
        (goto-char (point-max))
        (if (window-live-p (whizzy-get whizzy-process-window)) nil
          (set-mark (point-min)))
        (re-search-backward "<Recompilation failed>" (mark) 'move)
        (delete-region (point) (max (mark) (- (point-max) 35)))
        ;; (set-mark (point))
        (set-buffer (whizzy-get whizzy-active-buffer))
        (whizzy-delete-error-overlay)
        (whizzy-auto-show 0)
        (whizzy-error 'tex t)
        (whizzy-set-time t)
        )
       ((string-match "<Continuing>" s)
        (whizzy-check-errors)
        (set-buffer (whizzy-get whizzy-active-buffer))
        (whizzy-auto-show 1)
        )
       ((string-match "<Reformatting failed>" s)
        (whizzy-error 'fmt)
        (whizzy-auto-show 1))
       ((string-match "<Reformatting succeeded>" s)
        (whizzy-error 'fmt t)
        )
       ((string-match "<Pages and sections updated>" s)
        (whizzy-read-marks t))
       ((string-match "<Recompiling>" s)
        (whizzy-set-time nil)
        )
       ((string-match "<Recompilation failed>" s)
        (whizzy-error 'tex)
        (whizzy-set-time t)
        )
       ((string-match "<Error in Line \\([^\n]*\\) *>" s)
        (beginning-of-line)
        (goto-char (point-max))
        (previous-line 1)
        (set-buffer (whizzy-get whizzy-active-buffer))
        (whizzy-show-wdiff (match-string 1 s))
        (whizzy-auto-show 1)
        )
       ((string-match "\#line \\([0-9][0-9]*\\)" s)
        (whizzy-goto-line s)
        )
       ((string-match "<Fatal error>" s)
        (set-buffer (whizzy-get whizzy-active-buffer))
        (whizzy-mode-off)
        (whizzy-show-interaction t)
        (message "External Fatal error. WhizzyTeX Mode turn off. ")
        )
       ((string-match "<Quitting>" s)
        (set-buffer (whizzy-get whizzy-active-buffer))
        (whizzy-mode-off)
        (message "Mode turn off externally")
        )
       )))

(make-face 'whizzy-slice-face)
(set-face-background 'whizzy-slice-face "LightGray")
(set-face-foreground 'whizzy-slice-face "dim gray")

(defvar whizzy-slice-overlay nil)
(make-variable-buffer-local 'whizzy-slice-overlay)

(defun whizzy-create-slice-overlays ()
  (if (not whizzy-slice-overlay)
      (let ((beg (make-overlay 1 1)) (end (make-overlay 1 1)))
        (overlay-put beg 'face 'whizzy-slice-face)
        (overlay-put end 'face 'whizzy-slice-face)
        (setq whizzy-slice-overlay (cons beg end)))))

(defun whizzy-move-slice-overlays (&optional beg end)
  (if whizzy-slice-overlay
      (progn
        (move-overlay (car whizzy-slice-overlay)
                      (point-min) (or beg whizzy-last-slice-begin))
        (move-overlay (cdr whizzy-slice-overlay)
                      (or end whizzy-last-slice-end) (point-max)))))

(defun whizzy-delete-slice-overlays ()
  (if whizzy-slice-overlay
      (progn
        (delete-overlay (car whizzy-slice-overlay))
        (delete-overlay (cdr whizzy-slice-overlay)))))

;; to move according to the mode

(defun whizzy-next-slice (arg)
  "Move next slice"
  (interactive "p")
  (if whizzy-begin
      (let ((begin (concat "\\(^\\\\begin{document}\\|" whizzy-begin "\\)"))
            (end (concat "\\(^\\\\end *{document}\\|" whizzy-begin "\\)")))
        (cond
         ((> arg 0)
          (re-search-forward begin (point-max) t arg))
         ((< arg 0)
          (if (re-search-backward begin (point-min) t (- 1 arg))
              (goto-char (match-end 0)))
          t)
         )
        (recenter 2)
        (let* ((here (point))
               (beg (min (match-beginning 0) here))
              )
          (if (re-search-forward end (point-max) t)
              (whizzy-move-slice-overlays beg (match-beginning 0)))
          (goto-char here))
    )))

(defun whizzy-previous-slice (arg)
  "Move prior slice"
  (interactive "p")
  (whizzy-next-slice (- 0 arg))
  )


;;; moving pages in the previewer from the emacs buffer
;;; asumes you have a command sendkey (see the efuns ocaml xlib)

(defvar whizzy-sendkey-command "sendKey"
  "The name of the command to send keys to windows. 
It should accept the following arguments

   -name <WINDOW-NAME>
   -key  <KEY-NAME>
   <CHARACTERS-STRING>
"
)
(defun whizzy-toggle-error-report (&optional arg)
  (interactive "p")
  (setq whizzy-error-report (not whizzy-error-report)))

(defun whizzy-toggle-point (&optional arg)
  (interactive "p")
  (setq whizzy-point (not whizzy-point))
  (setq whizzy-last-tick 0)
  (setq whizzy-last-point 0)
  )
(defun whizzy-toggle-line ()
  "toggle whizzy-line variable"
  (interactive)
  (setq whizzy-line (not whizzy-line))
  (setq whizzy-last-tick 0)
  )

(defun whizzy-toggle-auto-show ()
  "toggle whizzy-show-output variable"
  (interactive)
  (setq whizzy-auto-show-output (not whizzy-auto-show-output))
  )
  

;;;; menus and bindings

(defun whizzy-help ()
  (interactive)
  (describe-function 'whizzytex-mode))

(defun whizzy-help-view-slice ()
  (interactive)
  (view-file (whizzy-get whizzy-slicename)))

(defun whizzy-view-log ()
  (interactive)
  (view-file
   (read-file-name "Log: " (whizzy-get whizzy-output-dir) "slice" t)))

(defun whizzy-slicing-paragraph () (interactive)
  (whizzy-change-mode 'paragraph)
  (setq whizzy-begin whizzy-paragraph-regexp)
  )

(defun whizzy-slicing-wide-paragraph () (interactive)
  (whizzy-change-mode 'paragraph)
  (setq whizzy-begin  "\n *\n *\n *\n")
  )

(defun whizzy-set-paragraph-regexp  () (interactive)
  (setq whizzy-paragraph-regexp
        (read-string "Paragraph regexp: "
                     (cons whizzy-paragraph-regexp 0) nil))
  (whizzy-slicing-paragraph)
  )

(defun whizzy-unmaster () (interactive)
  (whizzy-mode-off) (setq whizzy-slave nil))

(defun whizzy-slicing-mode-p (mode)
  (equal (whizzy-get whizzy-slicing-mode) mode))


(setq whizzy-mode-map nil)
(if whizzy-mode-map nil
  (if running-xemacs nil         ; if not running xemacs
    (setq whizzy-mode-map (make-sparse-keymap))
    (let ((map (make-sparse-keymap)))
      (define-key whizzy-mode-map [whizzy-help]
        '("Help" . whizzy-help))
      (define-key whizzy-mode-map [line-c] '("--" . ()))
      (define-key whizzy-mode-map [whizzy-view-log]
        '("View log..." . whizzy-view-log))
      (put 'whizzy-view-log 'menu-enable 'whizzy-mode)
      (define-key whizzy-mode-map [whizzy-show-interaction]
        '(menu-item "Show interaction"  whizzy-show-interaction
          (nil)
          ))
      (define-key whizzy-mode-map [line-a] '("--" . ()))
      (define-key whizzy-mode-map [whizzy-toggle-auto-show]
        '(menu-item "Auto interaction"  whizzy-toggle-auto-show
          (nil)
          :button
          (:toggle and whizzy-auto-show-output)))
      (define-key whizzy-mode-map [whizzy-toggle-line]
        '(menu-item "Page to point"  whizzy-toggle-line 
          (nil)
          :button
          (:toggle and whizzy-line)))
      (define-key whizzy-mode-map [whizzy-toggle-point]
        '(menu-item "Point visible"  whizzy-toggle-point 
          (nil)
          :button
          (:toggle and whizzy-point)))
      (define-key whizzy-mode-map [line-b] '("--" . ()))
      (define-key map [other]
         '("other" . whizzy-change-mode))
      (define-key map [paragraph-regexp]
         '("paragraph regexp" . whizzy-set-paragraph-regexp))
      (define-key map [line-a] '("--" . ()))
      (define-key whizzy-mode-map [whizzy-unmaster]
        '("Unmaster file" . whizzy-unmaster))
      (put 'whizzy-unmaster 'menu-enable 'whizzy-slave)
      (define-key whizzy-mode-map [whizzy-duplex]
        '("Duplex" . whizzy-duplex))
      (put 'whizzy-duplex 'menu-enable 'whizzy-mode)
      (define-key whizzy-mode-map [whizzy-suspend]
        '(menu-item "Suspend/Resume" whizzy-suspend
          (nil)
          :button
          (:toggle and (equal whizzy-mode 'suspended))))
      (put 'whizzy-suspend 'menu-enable 'whizzy-mode)
      (let ((modes whizzy-mode-regexp-alist) (mode))
        (while (and (consp modes) (consp (car modes)))
          (setq mode (caar modes))
          (if (equal mode 'none)
              (define-key map [line-b] '("--" . nil)))
          (define-key map (vector mode)
            (list
                  'menu-item
                  (symbol-name mode)
                  (list 'lambda nil
                        '(interactive) 
                        (list 'whizzy-change-mode  (list 'quote mode)
                              ))
                  (list nil)
                  ':button
                  (list ':radio 'whizzy-slicing-mode-p
                        (list 'quote mode))
                  ))
          ;; (put mode 'menu-enable (equal whizzy-mode mode))
          (setq modes (cdr modes))
          ))
      (define-key whizzy-mode-map [slicing] 
        (cons "Slicing"  map))
      (put 'map 'menu-enable 'whizzy-mode)
      (define-key whizzy-mode-map [whizzy-mode]
        '(menu-item "WhizzyTeX"  whizzytex-mode
          (nil)
          :button
          (:toggle and whizzy-mode)))
      )))

(defvar whizzy-xemacs-menu
  (if running-xemacs
      '("Whizzy"
        [ "WhizzyTeX" whizzytex-mode
          :style toggle :selected whizzy-mode ]
        ("Slicing"  
         [ "none" (whizzy-change-mode 'none) 
           :style radio :selected (whizzy-slicing-mode-p 'none) ]
         "---"
         [ "document" (whizzy-change-mode-p 'document) 
           :style radio
           :selected (whizzy-slicing-mode-p 'document) ]
         [ "section" (whizzy-change-mode 'section) 
           :style radio :selected (whizzy-slicing-mode-p 'section) ]
         [ "subsection" (whizzy-change-mode 'subsection) 
           :style radio :selected (whizzy-slicing-mode-p 'subsection) ]
         [ "subsubsection" (whizzy-change-mode 'subsubsection) 
           :style radio :selected (whizzy-slicing-mode-p 'subsubsection) ]
         [ "letter" (whizzy-change-mode 'letter) 
           :style radio :selected (whizzy-slicing-mode-p 'letter) ]
         [ "slide" (whizzy-change-mode 'slide) 
           :style radio :selected (whizzy-slicing-mode-p 'slide) ]
         "---"
         [ "other" whizzy-change-mode t ]
         )
        [ "Suspend/Resume" whizzy-suspend
          :style toggle :selected (equal whizzy-mode 'suspended) ]
        [ "Duplex" whizzy-duplex :active whizzy-mode ]
        [ "Unmaster" whizzy-unmaster :active whizzy-slave ]
        "---"
        [ "Page to point" whizzy-toggle-line
          :style toggle :selected whizzy-line :active whizzy-mode ]
        [ "Point visible" whizzy-toggle-point 
          :style toggle :selected whizzy-point :active whizzy-mode ]
        [ "Auto interaction" whizzy-toggle-auto-show 
          :style toggle :selected whizzy-auto-show-output :active whizzy-mode ]
        "---"
        [ "Show interaction" whizzy-show-interaction ]
        [ "View log..."  whizzy-view-log :active whizzy-mode ]
        [ "Help" whizzy-help t ]
        ))
  "Menu to add to the menubar when running Xemacs")

;; two useful hooks
(if running-xemacs
    (defun whizzy-suggested-hook ()
      "*Suggested hook for whizzytex
This installs the following bindings:

  Toggle WhizzyTeX mode         \\[whizzytex-mode]
  Move one slice forward        \\[whizzy-next-slice] 
  Move one slice backward       \\[whizzy-previous-slice]	

as well as a tool bar menu `whizzy-mode-map'.
"
      (local-set-key [menu-bar whizzy] (cons "Whizzy" whizzy-mode-map))
      (local-set-key [(control next)] 'whizzy-next-slice)
      (local-set-key [(control prior)] 'whizzy-previous-slice) 
      (local-set-key [?\C-c ?\C-w] 'whizzytex-mode)
      (local-set-key [?\C-c ?\C-s] 'whizzy-change-mode)
      (local-set-key [?\C-c ?\C-z] 'whizzy-suspend)
      (local-set-key [(control return)] 'whizzy-show-interaction) ;
      (eval '(if (and (featurep 'menubar) current-menubar)
                 (progn
                   (set-buffer-menubar current-menubar)
                   (add-submenu nil whizzy-xemacs-menu))))
      )

  (defun whizzy-suggested-hook ()
    "*Suggested hook for whizzytex
This installs the following bindings:

  Toggle WhizzyTeX mode         \\[whizzytex-mode]
  Move one slice forward        \\[whizzy-next-slice] 
  Move one slice backward       \\[whizzy-previous-slice]	
  Change slicing mode           \\[whizzy-change-mode]
  Suspend/Resume                \\[whizzy-suspend]

as well as a tool bar menu `whizzy-mode-map'.
"
    (local-set-key [menu-bar whizzy] (cons "Whizzy" whizzy-mode-map))
    (local-set-key [C-next] 'whizzy-next-slice)
    (local-set-key [C-prior] 'whizzy-previous-slice) 
    (local-set-key [?\C-c ?\C-s] 'whizzy-change-mode) 
    (local-set-key [?\C-c ?\C-w] 'whizzytex-mode)
    (local-set-key [?\C-c ?\C-z] 'whizzy-suspend)
    (local-set-key [C-return] 'whizzy-show-interaction))  
  )

(add-hook 'whizzytex-mode-hook 'whizzy-suggested-hook)

(defun whizzy-unset-options-hook ()
  "*Hook to unset some default options (WhizzyTeX may then run safer)"
  (setq whizzy-error-report nil)
  (setq whizzy-auto-show-output nil)
)
  
(provide 'whizzytex)

;;; whizzytex.el ends here
