;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  WhizzyTeX
;;  Didier Remy, projet Cristal, INRIA-Rocquencourt
;;  Copyright 2001 
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;  File whizzytex.el
;;
;;  Provides whizzy-mode for incrementally previewing the output of 
;;  TeX files 
;;  Part of the WhizzyTeX distribution


;;; Bindings

(defvar whizzytex-mode-hook nil
  "*Hook run when `whizzytex-mode' is turn on (at the end).

we suggest you to add to your emacs.el:

    (add-hook 'whizzytex-mode-hook (function whizzy-suggested-hook))

to obtain some whizzytex bindings (see `whizzy-suggested-hook')
To use remove all options, you can also add:

    (add-hook 'whizzytex-mode-hook (function whizzy-remove-options-hook)

")

;;; Configuration

(defvar whizzy-command-name "whizzytex"
  "*Short or full name of the WhizzyTeX deamon")

(defvar whizzy-view "-dvi \"xdvi\""
  "*Default previewer mode and command. 

A local value can be specifed in the header of the file. For instance,
the above setting could be obtained by insert the line:

%; whizzy <sub-mode> <previewer> <argument>

amongst the first lines of the file, where:

  <mode> is one of the modes slide, section, document or paragraph. 

  <previewer> is either -dvi or -ps and <argument> are arguments to be passed 
         to the whizzytex-shell script, in particular it should start with 
         the mandatory command to call the previewer (see the manual)
 
  <previewer> is -master and <argument> is the name of the master file.

")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; dead-code, changing frames changed the mouse
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; (defvar whizzy-frame-parameters
;   (if (and (functionp 'frame-parameter) (functionp 'select-frame-by-name))
;       '((width . 80) (height . 11)
;         (user-position . t) (top - 0) (left - 0)
;         (font . "6x10"))
;     nil)
;   "*By default whizzyitex shell is displayed in a separate frame
; with the following parameters that are passed to the \[make-frame] command.
; 
; You can adjust those parameters, or set this variable to nil if you do not 
; want the shell-buffer to appear in a different frame")
;;;;;;;;;;;;;;;;;;;;
(defvar whizzy-slicing-commands
  (list 'set-mark-command)
  "List of commands that should force a slice, anyway.
   Should remain small for efficiency...")

(defvar whizzy-line t
  "Save the current line number, so as to enable the previewer to jump
   to the corresponding page")
(make-variable-buffer-local 'whizzy-line)

(defvar whizzy-point t
  "Make point visible (and refresh when not too busy)")
(make-variable-buffer-local 'whizzy-point)

(defvar whizzy-paragraph-regexp "\n *\n *\n"
  "Regexp for paragraph mode")
(make-variable-buffer-local 'whizzy-paragraph-regexp)

(defvar whizzy-error-report
  (and (functionp 'make-overlay)
       (functionp 'delete-overlay)
       (functionp 'overlay-put))
  "when set to true  whizzy mode will overlay latex errors")

(defun whizzy-toggle-error-report (&optional arg)
  (interactive "p")
  (setq whizzy-error-report (not whizzy-error-report)))

;;; Also configurable, for adjustments
(defvar whizzy-mode-regexp-alist
  (append
   (list (cons 'paragraph whizzy-paragraph-regexp))
   '(
     (letter .  "^\\\\begin{letter}")
     (slide . "^\\\\\\(overlays *{?[0-9*]+}? *{[% \t\n]*\\\\\\)?\\(begin *{slide}\\|newslide\\)")
     (subsection .  "^\\\\\\(subsection\\|section\\|chapter\\)")
     (section .  "^\\\\\\(section\\|chapter\\)")
     (chapter .  "^\\\\\\(chapter\\)")
     (whole .  "^\\\\begin{document}\\(.*\n\\)+")
     (document . nil)
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
  "Alist mapping latex document slides to modes"
)

(defvar whizzy-select-mode-regexp-alist
  (list
    (cons "^ *\\\\begin *{slide}" 'slide )
    (cons "^ *\\\\\\(subsection\\|section\\|chapter\\)" 'section)
   )
  "Alist selecting modes from regexp"
)

(defvar whizzy-file-prefix "_whizzy_")
(defvar whizzy-pool-directory nil)
(defvar whizzy-speed-string "?")
(defvar whizzy-mode-line-string
  (list " Whizzy." 'whizzy-speed-string))

(defvar whizzy-shell-cd-command "cd"
  "Command to give to shell running wysitex to change directory.  The value of
whizzy-directory will be appended to this, separated by a space.")



;;; imports

(require 'comint)
(require 'shell)

;;; abstraction for xemacs compatibility

(defvar whizzy-running-xemacs
  (string-match "^[Xx][Ee]macs" (emacs-version)))
(defun whizzy-sit-for (seconds &optional milliseconds display)
  (sit-for seconds milliseconds display))

(if whizzy-running-xemacs
(defun whizzy-sit-for (seconds &optional milliseconds display)
  (sit-for
   (if milliseconds (+ (float seconds) (/ (float milliseconds) 1000))
     seconds)
   display))
)

(defun whizzy-window-buffer-height (&optional window)
  (save-selected-window
    (set-buffer (window-buffer window))
    (count-lines (point-min) (point-max))))
(if whizzy-running-xemacs nil
  (defun whizzy-window-buffer-height (&optional window)
    (window-buffer-height window)))

;;;

(defvar whizzy-pause 300
  "*Time in milliseconds after which the slice is saved if not other
keystoke occur. 

This variable is buffer-local and continuously adjusted dynamically, so 
its exact value does not matter too much." )

(make-variable-buffer-local 'whizzy-pause)
(defvar whizzy-shell-buffer-name "*whizzy-shell*")
(defvar whizzy-master nil
  "*if non-nil, name of the master file")
(make-variable-buffer-local 'whizzy-master)

(defvar whizzy-buffers nil)

(defun whizzy-message (mess &optional log-string log-file)
  (message mess)
  (save-excursion
   (if (get-buffer whizzy-shell-buffer-name)
       (progn 
         (set-buffer whizzy-shell-buffer-name)
         (goto-char (point-max))
         (beginning-of-line)
         (if (> (point) 1) (backward-char 1))
         (insert "\n\n*** " mess)
         (if log-string (insert log-string))
         (insert "\n\n")
         (if (and log-file (file-readable-p log-file))
             (insert-file log-file))
         (end-of-line))
     )
))
      
(defvar whizzy-layers nil)
(make-variable-buffer-local 'whizzy-layers)
(defvar whizzy-view-mode nil)
(make-variable-buffer-local 'whizzy-view-mode)

(defvar whizzy-marks nil)
(make-variable-buffer-local 'whizzy-marks)
(defvar whizzy-input-marks nil)
(defun whizzy-mark (elem)
  (setq whizzy-marks (cons elem whizzy-marks)))

(defun whizzy-read-marks (file &optional arg)
  (if (or whizzy-marks arg) (load-file file)))

(defun whizzy-clear-shell ()
  (save-excursion
    (if (get-buffer whizzy-shell-buffer-name)
        (whizzy-kill-job)
      (whizzy-start-shell))
    (set-buffer whizzy-shell-buffer-name)
    (setq comint-output-filter-functions
          (list (function whizzy-filter-output)))
    (erase-buffer)))
 
(defun whizzy-clean-shell ()
  (save-excursion
    (if (get-buffer whizzy-shell-buffer-name)
        (progn
          (set-buffer whizzy-shell-buffer-name)
          (goto-char (point-max))
          (if (or (> (buffer-size) 10000))
               (re-search-backward "Output written on" (point-min) t)
              (erase-buffer))))))

(defun whizzy-running (&optional arg)
  (let ((buffer-file-name (whizzy-buffer-file-name)))
    (if whizzy-input-marks
        (let ((pos (concat (file-name-directory buffer-file-name)
                           whizzy-file-prefix
                           (file-name-sans-extension
                            (file-name-nondirectory buffer-file-name))
                           ".pos")))
          (if (and (file-newer-than-file-p pos (buffer-file-name))
                   (file-readable-p pos))
              (progn 
                (whizzy-read-marks pos)
                (setq whizzy-input-marks nil)))
          ))
    (if (file-exists-p (concat "." whizzy-file-prefix
                               (file-name-nondirectory buffer-file-name)))
        t
      (whizzy-mode-off)
      (let ((log (concat "."
                         (file-name-sans-extension
                          (file-name-nondirectory buffer-file-name))
                         ".log")))
        (whizzy-message
         (concat "Spooling has been turned off (see log in " log ")")
         ":" (concat (file-name-nondirectory (whizzy-buffer-file-name)) log))
        nil)
      )))

(make-variable-buffer-local 'write-region-annotate-functions)
(defvar whizzy-write-at-begin-document nil)
(defvar whizzy-slice-file-name nil)
(make-variable-buffer-local 'whizzy-slice-file-name)

(defun whizzy-word-in-paragraph ()
  (if (eobp) nil
  (save-excursion
    (let* ((here (point)) (near here) (there) 
           (bol (progn (beginning-of-line) (point)))
;            (eol (progn (end-of-line) (point)))
           (bow (progn
                  (goto-char here)
                  (if (looking-at "[ \n]") (skip-chars-backward " "))
                  (setq near (point))
                  (skip-chars-backward "^ ")  
                  (point)))
;            (eow (progn
;                   (goto-char near)
;                   (skip-chars-forward "^ ")
;                   (point)))
            )
      (goto-char bol)
      (cond
       ((looking-at "$")
          (skip-chars-forward "\n")
          (setq there (point)))
       ((looking-at "\\\\"))
       ((progn (skip-chars-forward "^\\\\{}" bow) nil))
       ; now point if at bow
       ((and
         (looking-at "\\({\\\\[A-Za-z--]+\\)\\( [^\\\\\n}]*\\)?}")
          (goto-char 
           (if (< (match-end 0) bow) (match-end 0) (match-end 1)))
          (skip-chars-forward "^\\\\{}[]" bow)
          (< (point) bow)))
       ((looking-at
         "[()'`A-Za-z--éèàêâïùÉÈ]+[ \n,.:;--?!~}]")
        (setq there near))
       (t))
     there
     ))))


; (defun whizzy-write-slice (from to &optional local word)
;   (let ((old write-region-annotate-functions)
;         (coding coding-system-for-write))
;     (setq write-region-annotate-functions
;           (list 'whizzy-write-region-annotate))
;     (setq whizzy-write-at-begin-document (if local word 0))
;     (condition-case nil
;         (unwind-protect
;             (write-region from to whizzy-slice-file-name)
;           (setq write-region-annotate-functions old))
;       (quit (message "Quit occured during slicing has been ignored"))
;       )
;     (write-region from to whizzy-slice-file-name))
;   (whizzy-call "-wakeup"))

(defun whizzy-write-slice (from to &optional local word)
    (if local
        (let ((old write-region-annotate-functions)
;              (coding coding-system-for-write)
              )
          (setq write-region-annotate-functions
                (list 'whizzy-write-region-annotate))
          (setq whizzy-write-at-begin-document word)
          (condition-case nil
              (unwind-protect
                  (write-region from to whizzy-slice-file-name)
                (setq write-region-annotate-functions old))
            (quit (message "Quit occured during slicing has been ignored"))
            ))
      (write-region from to whizzy-slice-file-name))
  (whizzy-call "-wakeup"))
              
(defun whizzy-write-region-annotate (start end)
  (let ((empty-lines (count-lines (point-min) start))
        (full-lines (count-lines start (point)))
        (word (whizzy-word-in-paragraph)))
    (if (and word whizzy-point)
        (setq word
              (list (cons word ""))
              )
      (setq word nil))
    (if (not (numberp whizzy-write-at-begin-document))
        (append
         (list (cons start
                     (concat "\\begin{document}"
                             whizzy-write-at-begin-document
                             (make-string empty-lines 10)
                             (if whizzy-line ; (not whizzy-point)
                                 (concat
                                  "\\WhizzyLine{"
                                  (int-to-string (+ empty-lines full-lines))
                                  "}"))
                             )))
         word
         (list (cons end "\n\\end{document}\n")))
;       (save-excursion
;         (goto-char (point-min))
;         (append
;          (and whizzy-line
;               (search-forward "\\begin{document}" nil t)
;               (list
;                (cons (point)
;                      (concat
;                       "\\WhizzyLine{"
;                       (int-to-string (+ empty-lines full-lines))
;                       "}"))))
;          word))
      )
    ))

(defun whizzy-buffer-file-name ()
  (if whizzy-master (buffer-file-name whizzy-master)
    (buffer-file-name)))  

(defun whizzy-call (options &optional background)
  (let ((file (file-name-nondirectory (whizzy-buffer-file-name))))
    (process-send-string
     whizzy-shell-buffer-name
     (concat whizzy-shell-cd-command " "
             (expand-file-name default-directory) " ;"
             whizzy-command-name " " options " " file
             (if background
                 (concat " 2>."  (file-name-sans-extension file) ".log & \n")
               "\n")))
    ))

(defvar whizzy-last-tick 0)
(defvar whizzy-last-saved 0)
(defvar whizzy-last-point 0)
(make-variable-buffer-local 'whizzy-last-tick)
(make-variable-buffer-local 'whizzy-last-saved)
(make-variable-buffer-local 'whizzy-last-point)
(defvar whizzy-last-slice-begin 0)
(make-variable-buffer-local 'whizzy-last-slice-begin)
(defvar whizzy-last-slice-end 0)
(make-variable-buffer-local 'whizzy-last-slice-end)
(defvar whizzy-last-layer 0)
(make-variable-buffer-local 'whizzy-last-layer)

(defvar whizzy-begin nil)
(defvar whizzy-slicing-mode nil)
(make-variable-buffer-local 'whizzy-begin)
(make-variable-buffer-local 'whizzy-view)
(make-variable-buffer-local 'whizzy-slicing-mode)
(defun whizzy-local ()
  (not (equal whizzy-slicing-mode 'document)))

(defun whizzy-backward (&optional n)
  (if (re-search-backward whizzy-begin (point-min) t (or n 1))
      (let ((max (match-end 0)))
        (if (re-search-backward whizzy-begin (point-min) 'move)
            (goto-char (match-end 0)))
        (re-search-forward whizzy-begin max t)
        (goto-char (match-beginning 0))
        )))

(defvar whizzy-pause-adjust 0.5)
(make-variable-buffer-local 'whizzy-pause-adjust)
  
(defun whizzy-pause-adjust (arg)
  (let ((x (+ (* whizzy-pause-adjust 0.8) (if arg 0.2 0)))
        (y))
    (setq whizzy-pause-adjust x)
    (if (> x 0.6)
        (setq y (min (+ (* (- whizzy-pause 40) 2) 40) 5000))
      (if (< x 0.3)
          (setq y (max (+ (/ (- whizzy-pause 40) 2) 40) 50))))
    (if y
        (progn
          (setq whizzy-pause y)
          (setq whizzy-speed-string (int-to-string (/ y 100)))))
    ))

(defvar slice-mark-regexp "^\\\\\\(subsection\\|section\\)[^\n]*$")
(defun whizzy-slice (layer delayed)
  (if delayed
      (whizzy-pause-adjust (file-exists-p whizzy-slice-file-name)))
  (if (whizzy-local)
      (let ((here (point)) word)
        (if (or (whizzy-backward)
                (and
                 (re-search-backward "\\\\begin *{document}" (point-min) t)
                 (goto-char (match-end 0)))
                (and whizzy-master
                     (goto-char (point-min))))
            (progn
              (if (looking-at "\\\\begin{document}[ \t\n]*")
                  (goto-char (match-end 0)))
              (let ((from (point)) (next (match-end 0)) (line))
                (if (consp whizzy-marks)
                    (if (and (looking-at slice-mark-regexp)
                             (setq line (assoc (match-string 0) whizzy-marks))
                             )
                        (setq word (cdr line))
                      (if (and
                           (re-search-backward slice-mark-regexp (point-min) t)
                           (setq line (assoc (match-string 0) whizzy-marks)))
                          (setq word (concat (cdr line) (car line) 
                                             "[...]\\par\\medskip"))
                        )))
                (goto-char next)
                (if (and
                     (or (re-search-forward whizzy-begin (point-max) t)
                         (and whizzy-master
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
                                (concat "\\WhizzyTeXslide[" layer "]{"
                                        (int-to-string
                                         (count-lines (point-min) here))
                                        "}")))
                      (setq whizzy-last-layer layer)
                      (whizzy-write-slice from to t word)))
                ))
              (goto-char here)
              ))
          (whizzy-write-slice (point-min) (point-max)))
  )

(defvar whizzy-mode nil)
(make-variable-buffer-local 'whizzy-mode)
(setq minor-mode-alist (cdr minor-mode-alist))
(or (assoc 'whizzy-mode minor-mode-alist)
    (setq minor-mode-alist
          (cons (list 'whizzy-mode whizzy-mode-line-string)
                minor-mode-alist)))

(defvar whizzy-active-buffer  nil)
(defun whizzy-observe-changes (&optional ignore-check)
  (if executing-kbd-macro t
    (if (or whizzy-mode ignore-check)
        (let ((tick (buffer-modified-tick))
              (pos (point)) (layer) (tmp) (delayed)
              (error t))
          (unwind-protect
              (progn
                (if (or
                     (and
                     (or (if (/= tick whizzy-last-tick)
                             t
                           (if (or (buffer-modified-p)
                                   (= tick whizzy-last-saved))
                               nil
                             (setq whizzy-last-saved tick)
                             (whizzy-call "-wakeup")
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
                     (or (and (whizzy-sit-for 0 whizzy-pause)
                              (setq delayed t))
                         (> (- tick whizzy-last-tick) 10)))
                     (and whizzy-point
                          (not (equal (point) whizzy-last-point))
                          (whizzy-sit-for (/ whizzy-pause 100) whizzy-pause)))
                    (progn
                      (setq whizzy-active-buffer (current-buffer))
                      (whizzy-slice layer delayed)
                      (setq whizzy-last-tick tick)
                      ; (whizzy-clean-shell)
                      ))
                (if (and (not ignore-check)
                         (or (and whizzy-marks
                                  (not (consp whizzy-marks))
                                  (whizzy-sit-for 0 500))
                             (whizzy-sit-for 2)))
                    (whizzy-running))
                (setq error nil))
            (if (and error whizzy-mode)
                (progn
                  (message "*** Fatal Error while slicing")
                  (whizzy-mode-off)))
            ))
      (whizzy-mode-off))))



(defun whizzytex-mode (&optional arg)
  "\
Toggle whizzytex mode. 

With optional ARG, it sets mode on if ARG is positive, and off otherwise. 

It assigns default to parameters whenever possible. 
The user is only asked for  missing defaults, unless ARG is 4, in which 
case, the principal parameters must be confirmed.

See help on the main configuration variables

  `whizzy-view'
  `whizzy-command-name'

The command evaluates `whizzytex-mode-hook'."
  (interactive "P")
  (let ((new-mode 
          (if (null arg)
              (not (and whizzy-mode (whizzy-running)))
              (> (prefix-numeric-value arg) 0))))
    (unless (eq new-mode whizzy-mode)
      (if new-mode (whizzy-mode-on (prefix-numeric-value arg))
        (whizzy-mode-off))))
  whizzy-mode)

(defvar whizzy-mode-map nil 
  "*Keymap used in `whizzytex-mode'")

(defun whizzy-buffer-off (buf)
  (if (buffer-live-p buf)
      (progn
        (set-buffer buf)
        (if whizzy-mode
            (shell-command
             (concat 
              "cd " (file-name-directory buffer-file-name) "; "
              whizzy-command-name " -kill "
              (file-name-nondirectory buffer-file-name))))
              )))
(defun whizzy-kill-emacs-hook ()
  (mapcar 'whizzy-buffer-off whizzy-buffers))

(defun whizzy-mode-on (&optional query)
  (if (not (whizzy-setup query))
      (progn
        (message "Setup failed. Turning mode off")
        (whizzy-mode-off))
    (whizzy-create-slice-overlays)
    (make-local-hook 'post-command-hook)
    (make-local-hook 'kill-buffer-hook)
    (add-hook 'kill-buffer-hook 'whizzy-mode-off t t)
    (add-hook 'post-command-hook 'whizzy-observe-changes t t)
    (add-hook  'kill-emacs-hook 'whizzy-kill-emacs-hook t)
    (whizzy-clear-shell)
    (if (not whizzy-master)
        (let ((dir (file-name-directory whizzy-slice-file-name)))
          (if (not (file-exists-p dir)) (make-directory dir))))
    (whizzy-observe-changes t)
    (if (not whizzy-master)
        (whizzy-call
         (concat
          (if (equal whizzy-slicing-mode 'slide) nil "-marks ")
          whizzy-view) t))
    (setq whizzy-last-tick -1)
    ; (use-local-map whizzy-mode-map)
    (setq whizzy-mode t)
    (if (not (member (current-buffer) whizzy-buffers))
        (setq whizzy-buffers (cons (current-buffer) whizzy-buffers)))
    ; (whizzy-show-frame)
    ))

(defun whizzy-mode-off (&optional arg)
  "Turn WhizzyTeX mode off"
  (interactive "p")
  (remove-hook  'post-command-hook 'whizzy-observe-changes t)
  (remove-hook  'kill-buffer-hook 'whizzy-mode-off t)
  (if (not whizzy-master)  (whizzy-call "-kill"))
  (whizzy-delete-slice-overlays)
  (whizzy-delete-error-overlay)
  (setq whizzy-mode nil))


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
        (or mode 'whole)
        ))))

(defun whizzy-setup-mode (mode)
  "Adjust local variables according to mode"
  (setq whizzy-pause-adjust 0.5)
  (setq whizzy-begin (cdr (assoc mode whizzy-mode-regexp-alist)))
  (cond
   ((null mode)
    (error "Mode should be a non-nil atom"))
   ((or (equal mode 'section) (equal mode 'subsection))
    (setq whizzy-marks (or whizzy-marks t)))

   ((equal mode 'paragraph)
    (setq whizzy-marks (or whizzy-marks t))
    (let ((str (whizzy-string-from-file "whizzy-paragraph" 1)))
      (setq whizzy-begin
            (or (and str  (car (read-from-string str)))
                (cdr (assoc mode whizzy-mode-regexp-alist))
                whizzy-begin)))
    )

   ((equal mode 'slide)
    (setq whizzy-marks nil)
    (save-excursion
      (goto-char (point-min))
      (if (or (re-search-forward
               "^\\\\documentclass *\\[\\([^]{}\n]*,\\)*semlayer\\(,[^]{}\n]*\\)*\\]"
               (point-max) t)
              (re-search-forward "\\\\overlay *{?[0-9*]" (point-max) t))
          (setq whizzy-layers t))))
   ((equal mode 'letter)
    (setq whizzy-marks nil))
   ((member mode '(subsection section chapter document whole))
    (setq whizzy-marks t))
   (t
    (error "Ill-formed mode"))
   )
  (if (and (null whizzy-begin) (not (equal mode 'document)))
      (error "Ill-formed slicing mode or incomplete whizzy-mode-regexp-alist"))
  (setq whizzy-slicing-mode mode)
  )



(defun whizzy-read-mode (&optional default)
  (interactive)
  (let ((table
         (mapcar (lambda (x) (cons (symbol-name (car x)) (car x)))
                 whizzy-mode-regexp-alist)))
    (cdr (assoc (completing-read "Mode: " table nil t (symbol-name default))
                table))))

(defun whizzy-change-mode (&optional mode)
  (interactive)
  (if (null mode)
      (setq mode (whizzy-read-mode whizzy-slicing-mode)))
  (if (null mode) (error "Ill formed mode"))
  (whizzy-setup-mode mode)
;   (if (equal mode 'paragraph)
;       (setq whizzy-begin
;             (read-from-minibuffer "Slice regexp: "
;                                   (regexp-quote whizzy-begin))))
  (whizzy-delete-slice-overlays)
  (setq whizzy-last-slice-begin 0)
  (setq whizzy-last-slice-end 0)
  (setq whizzy-last-tick -1)
  )

(defun whizzy-read-mode-from-file ()
  (let ((mode (whizzy-string-from-file "whizzy" 1 "\\([^ \n]+\\)[^\n]*")))
      (if mode
          (if (setq mode
                    (assoc mode
                           (mapcar (lambda (x) (cons (symbol-name (car x))
                                                     (car x)))
                                   whizzy-mode-regexp-alist)))
              (setq mode (cdr mode))
            (goto-char (set-mark (point)))
            (whizzy-string-from-file "whizzy" 1 "\\([^ \n]+\\)[^\n]*")
            (goto-char (match-end 1))
            (error
             (concat
              "Slicing mode ``" mode
              "'' is not valid. Use: document, section, slide, or paragraph")))
        (setq mode (whizzy-auto-mode)))
      mode))
    
(defun whizzy-setup-view-mode (mode)
  (setq whizzy-view-mode mode)
  (let ((long-name
         (concat whizzy-file-prefix
                 (file-name-sans-extension
                  (file-name-nondirectory
                   (or (whizzy-buffer-file-name)
                       (error
                        "Buffer has no associated file name"))
                   )))))
    (if (file-accessible-directory-p long-name) nil
      (make-directory long-name))
    (setq whizzy-slice-file-name
          (concat long-name "/" long-name ".new"))
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
    ))

(defun whizzy-setup-master (master)
  (save-excursion
    (let ((master-buffer (get-file-buffer master)) ; find-buffer-visiting
          (this-buffer (current-buffer))
          (name) (view) (mode))
      (set-buffer master-buffer)
      (if whizzy-mode
          (progn 
            (setq name whizzy-slice-file-name)
            (setq view whizzy-view)
            (setq mode whizzy-view-mode)
            )
        (error "The master file should be running wyzzitex"))
      (set-buffer this-buffer)
      (if name
          (progn
            (setq whizzy-slice-file-name name)
            (setq whizzy-view view)
            (setq whizzy-view-mode mode)
            )
        (error "Fatal name should not be nil here"))
      (setq whizzy-master master-buffer)
      )))

(defun whizzy-setup (&optional query)
  (run-hooks 'whizzytex-mode-hook)
  (if (and (local-variable-p 'whizzy-slicing-mode (current-buffer))
           (not (equal query 16)))
      nil
    (setq whizzy-slicing-mode (whizzy-read-mode-from-file)))
  (if (equal query 4)
      (setq whizzy-slicing-mode (whizzy-read-mode whizzy-slicing-mode)))
  (whizzy-setup-mode whizzy-slicing-mode)

  (let ((view))
    (if (and (local-variable-p 'whizzy-view (current-buffer))
             (not (equal query 16)))
        nil
      (if (setq view
                (whizzy-string-from-file "whizzy" 1
                                         "[^ \n]+ +\\([^\n]*[^ \n]*\\)"))
          nil
        (setq query 4)))
    (if (equal query 4)
        (setq view (read-string "View command: " (or view whizzy-view))))
    (if view
        (progn
          (if (string-match "^\\(-default\\) +\\(.*\\)$" view)
              (if (local-variable-p 'whizzy-view)
                  (setq view (concat whizzy-view " " (match-string 2)))
                (setq view whizzy-view)))
          (if (string-match "^\\([^ ]+\\) +\\(.*\\)$" view)
              (let ((first (match-string 1 view))
                    (second (match-string 2 view)))
                (cond
                 ((member first '("-ps" "-dvi"))
                  (whizzy-setup-view-mode first))
                 ((equal first "-master")
                  (whizzy-setup-master second))
                 (t
                  (error (concat "Viewer type " first
                                 " should be either -ps or -dvi")))))
            (error
             "Viewer command should match be of the form  TYPE ARGUMENT"))
          (setq whizzy-view view)))
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


(defun whizzy-start-shell ()
  (require 'shell)
  (save-excursion
    (set-buffer (make-comint "whizzy-shell" "bash" nil "-v"))
    (if (zerop (buffer-size))
        (sleep-for 1))))

(defun whizzy-kill-job ()
  "Kill the currently running whizzytex job."
  (interactive)
  (quit-process "whizzy-shell" t))

(defun whizzy-recenter-output-buffer (linenum)
  "Redisplay buffer of whizzytex job output so that most recent output 
can be seen. The last line of the buffer is displayed on line LINE of 
the window, or centered if LINE is nil."
  (interactive "P")
  (let ((tex-shell (get-buffer whizzy-shell-buffer-name))
        (old-buffer (current-buffer)))
    (if (null tex-shell)
        (message "No wysitex output buffer")
      (pop-to-buffer tex-shell)
      (bury-buffer tex-shell)
      (goto-char (point-max))
      (recenter (if linenum
                    (prefix-numeric-value linenum)
                  (/ (window-height) 2)))
      (pop-to-buffer old-buffer)
      )))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; using a separate frame for the output buffer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Dead code, since it did not behave well
;; (the mouse position is moved when selecting a new frame) 
;;
; (defvar whizzy-frame nil)
; (defun whizzy-show-frame ()
;   (interactive)
;   (if (and whizzy-frame-parameters
;            (not (and whizzy-frame
;                      (frame-live-p (car (memq  whizzy-frame (frame-list)))))
;            ))
;       (let ((current-frame-name (frame-parameter nil 'name)))
;         (setq whizzy-frame
;               (make-frame
;                (append
;                 '((name . "wysitex")
;                   (minibuffer . nil)
;                   (menu-bar-lines . 0)
;                   )
;                 whizzy-frame-parameters))
;               )
;         (select-frame whizzy-frame)
;         (switch-to-buffer (get-buffer whizzy-shell-buffer-name))
;         (select-frame-by-name current-frame-name)
;         (raise-frame)
;         )))
;
; (defun whizzy-view-output ()
;   (interactive)
;   (view-buffer-other-window whizzy-shell-buffer-name)
;   (toggle-read-only nil))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; errors

(defvar whizzy-latex-error-regexp
  "^\\(! Missing \\|! Undefined \\|! LaTeX Error:\\|Runaway argument?\\)")

(defun whizzy-check-errors (&optional buff)
  (interactive "p")
  (let ((source-buffer (or buff (current-buffer)))
        (shell-buffer (get-buffer whizzy-shell-buffer-name))
        ; (current-frame-name (frame-parameter nil 'name))
        (error-begin) (error-end) (line-string)
        (shell-moveto))
    (set-buffer shell-buffer)
    (goto-char (point-max))
    (re-search-backward "compilation failed>" (point-min) 'move)
    (delete-region (point-min) (- (point) 20))
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
    (if shell-moveto
        (unwind-protect
            (progn
              ; (select-frame whizzy-frame)
              (goto-char shell-moveto)
              ; (recenter 0)
              )
          ; (select-frame-by-name current-frame-name)
          ))
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

;; overlays and frames do not currently work in xemacs. 
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

(defvar whizzy-shell-window nil)
(make-variable-buffer-local 'whizzy-shell-window)
(defun whizzy-show-shell (&optional arg)
  "Display whizzytex process buffer"
  (interactive "P")
  (message (buffer-name))
  (let ((buf (current-buffer))
        (hide (if (null arg)
                  (and whizzy-shell-window
                       (window-live-p whizzy-shell-window))
                (= arg 0)))
        (shell  (get-buffer whizzy-shell-buffer-name))
        (height (window-height))
        (window)
;        (here (selected-window))
        (resize))
    (if hide
        (if (and whizzy-shell-window (window-live-p whizzy-shell-window))
            (progn
              (delete-window whizzy-shell-window)
              (bury-buffer shell)
              (setq whizzy-shell-window nil)))
      (if (equal buf whizzy-active-buffer)
          (save-selected-window
            (if (and  whizzy-shell-window
                      (window-live-p whizzy-shell-window)
                      (equal
                       (buffer-name (window-buffer whizzy-shell-window))
                       whizzy-shell-buffer-name))
                (select-window whizzy-shell-window)
              (setq height (* (/ height 3) 2))
              (split-window-vertically height)
              (goto-next-window)
              (switch-to-buffer shell t)
              )
            (setq window (selected-window))
            (setq resize
                  (- (window-height)
                     (max 3 (min (whizzy-window-buffer-height window)
                                 (/ (+ (window-height) height) 3)))))
            (goto-previous-window)
            (enlarge-window resize)
            ))
      (setq whizzy-shell-window window))
    ))

(defvar whizzy-auto-show-output t
  "*When true the shell output buffer will appear and disappear 
automatically, according to errors")
(defun whizzy-auto-show (arg)
  (if (and whizzy-auto-show-output
           (or (= arg 0) (sit-for 1)))
      (whizzy-show-shell arg)))

(defun whizzy-filter-output (s)
  (if whizzy-error-report
      (cond
       ((string-match "compilation succeeded>" s)
        (re-search-backward "<Reformatting failed" (point-min) 'move)
        (delete-region (point) (- (point-max) 23))
        (set-mark (point))
;         (if (search-backward "compilation succeeded" (- (point) 25) t)
;             (delete-region (point-min) (match-beginning 0)))
        (set-buffer whizzy-active-buffer)
        (whizzy-delete-error-overlay)
        (whizzy-auto-show 0)
            )
       ((string-match "<Continuing>" s)
        (whizzy-check-errors whizzy-active-buffer)
        (set-buffer whizzy-active-buffer)
        (whizzy-auto-show 1)
        )
       ((string-match "<Reformatting failed>" s)
        (whizzy-auto-show 1)
        )
       ((string-match "<Reformatting succedded>" s)
        (delete-region (point-min) (- (point-max) 23))
        )
       ((string-match "<Pages and sections updated>" s)
        (set-buffer whizzy-active-buffer)
        (setq whizzy-input-marks t)
  ;      (whizzy-auto-show 0)
        )
       ((string-match "<Error in Line \\([^\n]*\\) *>" s)
        (beginning-of-line)
        (goto-char (point-max))
        (previous-line 1)
        (set-buffer whizzy-active-buffer)
        (whizzy-show-wdiff (match-string 1 s))
        (whizzy-auto-show 1)
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
(defvar whizzy-send-alist
  '(("-ps" .
     ((prior . "p") (next . "f")
      (home . "-key Home ") (end . "-key End ")))
    ("-dvi" .
     ((prior . "p") (next . "n")
      (home . "1g") (end . "g")))))

(defvar whizzy-send-name
  '(("-ps" . ("'[Gg][Vv].*" . "\\.\\(dvi\\|ps\\)'"))
    ("-dvi" . ("'.*[Xxl][Dd][Vv][Ii].*" . "\\.dvi'"))))

(defun whizzy-send-key (key &optional arg)
  (if (null whizzy-view-mode)
      (error "Unknown view-mode")
    (let ((string
           (assoc key (cdr (assoc whizzy-view-mode whizzy-send-alist))))
          (name
           (regexp-quote
            (file-name-sans-extension
             (file-name-nondirectory whizzy-slice-file-name))))
          (fix (cdr (assoc whizzy-view-mode  whizzy-send-name))))
      (setq name (concat (car fix) name (cdr fix)))
      (if (not (consp string))
          (error "send key: undefined key")
        (setq string (cdr string))
        (if (and (integerp arg) (> arg 1))
            (setq string
                  (eval (cons 'concat (make-list arg string)))))
        (process-send-string
         whizzy-shell-buffer-name
         (concat whizzy-sendkey-command " -name " name " " string "\n")))
      )))
  
(defun whizzy-send-home (arg) (interactive "p") (whizzy-send-key 'home))
(defun whizzy-send-next (arg) (interactive "p") (whizzy-send-key 'next arg))
(defun whizzy-send-prior (arg) (interactive "p") (whizzy-send-key 'prior arg))
(defun whizzy-send-end (arg) (interactive "p") (whizzy-send-key 'end))

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
        (read-string "Paragraph regexp: " whizzy-paragraph-regexp nil))
  (whizzy-slicing-paragraph)
  )

(defun whizzy-slicing-subsection () (interactive)
  (whizzy-change-mode 'subsection))
(defun whizzy-slicing-section () (interactive)
  (whizzy-change-mode 'section))
(defun whizzy-slicing-letter () (interactive)
  (whizzy-change-mode 'letter))
(defun whizzy-slicing-document () (interactive)
  (whizzy-change-mode 'document))
(defun whizzy-slicing-whole () (interactive)
  (whizzy-change-mode 'whole))

(setq whizzy-mode-map nil)
(if whizzy-mode-map nil
  (if whizzy-running-xemacs nil         ; if not running xemacs
    (setq whizzy-mode-map (make-sparse-keymap))
    (let ((map (make-sparse-keymap)))
      (define-key whizzy-mode-map [whizzy-help]
        '("Help" . whizzy-help))
      (define-key whizzy-mode-map [none] '(separator-edit "--"))
      (define-key map [other]
         '("other" . whizzy-change-mode))
      (define-key map [paragraph-regexp]
         '("paragraph regexp" . whizzy-set-paragraph-regexp))
      (define-key map [none] '("--" . ()))
      (let ((modes whizzy-mode-regexp-alist) (mode))
        (while (and (consp modes) (consp (car modes)))
          (setq mode (car (car modes)))
          (define-key map (vector mode)
            (cons (symbol-name mode)
                  (list 'lambda nil
                        '(interactive) 
                        (list 'whizzy-change-mode  (list 'quote mode)
                              ))))
          (message (int-to-string (length modes)))
          (setq modes (cdr modes))
          ))
      (define-key whizzy-mode-map [slicing] 
        (cons "Slicing"  map))
      (put 'whizzy-change-mode 'menu-enable 'whizzy-mode)
      (define-key whizzy-mode-map [whizzy-toggle-auto-show]
        '(menu-item "Auto show output"  whizzy-toggle-auto-show
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
      ; (put 'whizzy-toggle-line 'menu-enable 'whizzy-mode)
      (define-key whizzy-mode-map [whizzy-mode]
        '(menu-item "WhizzyTeX"  whizzytex-mode
          (nil)
          :button
          (:toggle and whizzy-mode)))
      )))


;; two useful hooks

(defun whizzy-suggested-hook ()
  "*Suggested hook for whizzytex

This installs the following bindings:

  Toggle WhizzyTeX mode         \\[whizzytex-mode]
  Move one slice forward        \\[whizzy-next-slice] 
  Move one slice backward       \\[whizzy-previous-slice]	

as well as a tool bar menu `whizzy-mode-map'.
"
  (local-set-key [menu-bar whizzy] (cons "Whizzy" whizzy-mode-map))
  (local-set-key [C-next] 'whizzy-next-slice)
  (local-set-key [C-prior] 'whizzy-previous-slice) 

  (local-set-key [C-M-home] 'whizzy-send-home)  
  (local-set-key [C-M-end] 'whizzy-send-end)    
  (local-set-key [C-M-next] 'whizzy-send-next)  
  (local-set-key [C-M-prior] 'whizzy-send-prior)

  (local-set-key "\C-c\C-w" 'whizzytex-mode)
  (local-set-key [C-return] 'whizzy-show-shell)
)

(defun whizzy-unset-options-hook ()
  (setq whizzy-error-report nil)
  (setq whizzy-auto-show-output nil)
)
  
;;;;

