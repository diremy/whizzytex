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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Xemacs compatibility

(defun whizzy-sit-for (seconds &optional milliseconds display)
  (sit-for seconds milliseconds display))

(if (not (boundp 'running-xemacs)) (defvar running-xemacs))
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


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

%; whizzy <sub-mode> <previewer> <command> <arguments>

amongst the first lines of the file, where:

  <mode> is one of the modes slide, section, document or paragraph.
        it is only interpreted by emacs

Usually, 

  <previewer> is one of -ps, -dvi, or -advi
        it is interpretted by emacs and also passed to the whizzytex script

  <command> 
        is only passed to the whizzytex script (not interpreted by emacs)
        this is the command that whizzytex should call to launch the
        previewer (see the manual). 

  <arguments>
        is the remaining of the lines and are extra-arguments passed to
        the whizzytex script (see the manual). 

However, when the file is an auxilliary file input by a master file, 
the master file should run whizzytex and the auxilliary file should set

  <previewer> to -master

  <command> to the name of the master file.
")

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
     (letter .  "\\(^\\|%WHIZZY\\)\\\\begin{letter}")
     (slide . "\\(^\\|%WHIZZY\\)\\\\\\(overlays *{?[0-9*]+}? *{[% \t\n]*\\\\\\)?\\(begin *{slide}\\|newslide\\)")
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


(defvar whizzy-pause 300
  "*Time in milliseconds after which the slice is saved if not other
keystoke occur. 

This variable is buffer-local and continuously adjusted dynamically, so 
its exact value does not matter too much." )

(make-variable-buffer-local 'whizzy-pause)
(defconst whizzy-shell-buffer-name "*whizzy-shell*")
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
           (bow (progn
                  (goto-char here)
                  (if (looking-at "[ \n]") (skip-chars-backward " "))
                  (setq near (point))
                  (skip-chars-backward "^ ")  
                  (point)))
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
                     (concat "\\begin{document}\\WhizzySkip"
                             whizzy-write-at-begin-document
                             (make-string empty-lines 10)
                             "\\WhizzyStart"
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
    (if (get-buffer whizzy-shell-buffer-name) nil
      (whizzy-clear-shell))
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
  (not (equal whizzy-slicing-mode 'none)))

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
If ARG is null, it switches whizzytex mode. 

Otherwise, according to the numeric value of ARG it turns mode off (< 0)
or on (>= 0). 

Turning the mode on assigns (or reassigns) default values to parameters 
whenever possible, reading the top for possible  local values. By default, 
the user is only asked when some parameters are missing and cannot be
assigned default values, with the following exception:

If ARG is 4, the user is asked interactively to confirm/change the principal
parameters (default values are previously assign if the is the first
invocation. Otherwise, default values are not reassigned)

If the mode is turn on explicitly (with prefix arg) when it is already on, 
then the mode is first turn off then on (hence, the single call
``C-0 \\[whizzytex-mode]'' will kill and restart whizzytex, which could also
be done by two sucessive calls ``\\[whizzytex-mode] \\[whizzytex-mode]'' 
to whizzytex-mode with no argument). 

See help on the main configuration variables

  `whizzy-view'
  `whizzy-command-name'

The command evaluates `whizzytex-mode-hook'."
  (interactive "P")
  (let ((new-mode 
          (if (null arg)
              (not (and whizzy-mode (whizzy-running)))
              (>= (prefix-numeric-value arg) 0))))
    (if (and whizzy-mode
             (or (not new-mode) (not (null arg))))
        (progn (whizzy-mode-off) (whizzy-sit-for 1)))
    (if (and new-mode (not whizzy-mode))
        (whizzy-mode-on (prefix-numeric-value arg))))
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
  (if (not (whizzy-setup (= query 4)))
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
        (or mode 'document)
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
   ((member mode '(subsection section chapter document none))
    (setq whizzy-marks t))
   (t
    (error "Ill-formed mode"))
   )
  (if (and (null whizzy-begin) (not (equal mode 'none)))
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
  (let ((mode-string
         (whizzy-string-from-file "whizzy" 1 "\\([^ \n]+\\)[^\n]*"))
        (mode-begin (match-beginning 1))
        (mode-end (match-end 1))
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
  (or
   ; do not reset of query or already bound
   (and query (local-variable-p 'whizzy-slicing-mode (current-buffer)))
   ; reset otherwise
   (setq whizzy-slicing-mode (whizzy-read-mode-from-file)))
  (if query
      (setq whizzy-slicing-mode (whizzy-read-mode whizzy-slicing-mode)))
  (whizzy-setup-mode whizzy-slicing-mode)
  (let ((view))
    (or
     ; do not reset if query and already locally bound
     (and query (local-variable-p 'whizzy-view (current-buffer)))
     ; attempt to resert otherwise
     (setq view (whizzy-string-from-file "whizzy" 1
                                         "[^ \n]+ +\\([^\n]*[^ \n]*\\)"))
     ; no local binding: do not query if already bound
     (local-variable-p 'whizzy-view (current-buffer))
     ; otherwise query
     (setq query t))
    (if query
        (setq view (read-string "View command: " (or view whizzy-view))))
    ; view is optional, whizzy-view has a default-value (there should always be a default value)
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
                 ((member first '("-ps" "-dvi" "-advi"))
                  (whizzy-setup-view-mode first))
                 ((equal first "-master")
                  (whizzy-setup-master second))
                 (t
                  (error (concat "Viewer type " first
                                 " should be either -ps, -dvi, or -dvi")))))
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


;;; errors

(defvar whizzy-latex-error-regexp
  "^\\(! Missing \\|! Undefined \\|! LaTeX Error:\\|Runaway argument?\\)")

(defun whizzy-check-errors (&optional buff)
  (interactive "p")
  (let ((source-buffer (or buff (current-buffer)))
        (shell-buffer (get-buffer whizzy-shell-buffer-name))
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
(defun whizzy-show-interaction (&optional arg)
  "Display whizzytex process buffer"
  (interactive "P")
  (if (or whizzy-mode whizzy-active-buffer) ; 
    (let ((buf (current-buffer))
          (hide (if (null arg)
                    (and whizzy-shell-window
                         (window-live-p whizzy-shell-window))
                  (= (prefix-numeric-value arg) 0)))
          (shell  (get-buffer whizzy-shell-buffer-name))
          (height (window-height))
          (window)
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
        (setq whizzy-shell-window window))
      )
    ))

(defvar whizzy-auto-show-output t
  "*When true the shell output buffer will appear and disappear 
automatically, according to errors")
(defun whizzy-auto-show (arg)
  (if (and whizzy-auto-show-output
           (or (= arg 0)
               (or (and running-xemacs
                        (= whizzy-last-tick (buffer-modified-tick)))
                   (whizzy-sit-for 1))))
      (whizzy-show-interaction arg)))

(defun whizzy-goto-line (buffer s)
  (if (string-match
"\#line \\([1-9][0-9]*\\), \\([1-9][0-9]*\\) <<\\(.*\\)>><<\\(.*\\)>>"
       s)
      (let ((line (string-to-int (match-string 1 s)))
            (bound (string-to-int (match-string 2 s)))
            (before (match-string 3 s))
            (after (match-string 4 s))
            (word)
            )
        (set-buffer buffer)
        (goto-line bound)
        (end-of-line)
        (setq bound (point))
        (goto-line line)
        (setq word
             (concat "[^A-Za-z0-9]\\(" (regexp-quote before)
                     "\\)\\(" (regexp-quote after)
                     "\\)[^A-Za-z0-9]"))
        (if (re-search-forward word bound t)
            (goto-char (match-end 1)))
        (whizzy-observe-changes)
        ))
    )

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
       ((string-match "\#line \\([1-9][0-9]*\\)" s)
        (whizzy-goto-line whizzy-active-buffer s)
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
      (home . "1g") (end . "g")))
    ("-advi" .
     ((prior . "p") (next . "n")
      (home . "1g") (end . "g")))
    ))

(defvar whizzy-send-name
  '(("-ps" . ("'[Gg][Vv].*" . "\\.\\(dvi\\|ps\\)'"))
    ("-dvi" . ("'.*[Xxl][Dd][Vv][Ii].*" . "\\.dvi'"))
    ("-advi" . ("'.*[Xxl][Dd][Vv][Ii].*" . "\\.dvi'"))
    ))

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
        (read-string "Paragraph regexp: "  (cons whizzy-paragraph-regexp 0) nil))
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
(defun whizzy-slicing-none () (interactive)
  (whizzy-change-mode 'none))

(setq whizzy-mode-map nil)
(if whizzy-mode-map nil
  (if running-xemacs nil         ; if not running xemacs
    (setq whizzy-mode-map (make-sparse-keymap))
    (let ((map (make-sparse-keymap)))
      (define-key whizzy-mode-map [whizzy-help]
        '("Help" . whizzy-help))
      (define-key whizzy-mode-map [line-a] '("--" . ()))
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
      (define-key whizzy-mode-map [line-b] '("--" . ()))
      (define-key map [other]
         '("other" . whizzy-change-mode))
      (define-key map [paragraph-regexp]
         '("paragraph regexp" . whizzy-set-paragraph-regexp))
      (define-key map [line-a] '("--" . ()))
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
                  (list ':radio 'equal 'whizzy-slicing-mode
                        (list 'quote mode))
                  ))
          (put mode 'menu-enable (equal whizzy-mode mode))
          (message (int-to-string (length modes)))
          (setq modes (cdr modes))
          ))
      (define-key whizzy-mode-map [slicing] 
        (cons "Slicing"  map))
      (put 'map 'menu-enable 'whizzy-mode)
      (define-key whizzy-mode-map [whizzy-show-interaction]
        '(menu-item "Show interaction"  whizzy-show-interaction
          (nil)
          ))
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
        [ "Show interaction" whizzy-show-interaction ]
        ("Slicing"  
         [ "none" (whizzy-change-mode 'none) 
            :style radio :selected (equal whizzy-slicing-mode 'none) ]
         "---"
         [ "document" (whizzy-change-mode 'document) 
            :style radio :selected (equal whizzy-slicing-mode 'document) ]
         [ "section" (whizzy-change-mode 'section) 
            :style radio :selected (equal whizzy-slicing-mode 'section) ]
         [ "subsection" (whizzy-change-mode 'subsection) 
            :style radio :selected (equal whizzy-slicing-mode 'subsection) ]
         [ "letter" (whizzy-change-mode 'letter) 
            :style radio :selected (equal whizzy-slicing-mode 'letter) ]
         [ "slide" (whizzy-change-mode 'slide) 
            :style radio :selected (equal whizzy-slicing-mode 'slide) ]
         "---"
         [ "other" whizzy-change-mode t ]
         )
        "---"
        [ "Page to point" whizzy-toggle-line
          :style toggle :selected whizzy-line :active whizzy-mode ]
        [ "Point visible" whizzy-toggle-point 
          :style toggle :selected whizzy-point :active whizzy-mode ]
        [ "Auto show output" whizzy-toggle-auto-show 
          :style toggle :selected whizzy-auto-show-output :active whizzy-mode ]
        [ "Help" whizzy-help t ]))
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

;       (local-set-key [(control meta home)] 'whizzy-send-home)  
;       (local-set-key [(control meta end)] 'whizzy-send-end)    
;       (local-set-key [(control meta next)] 'whizzy-send-next)  
;       (local-set-key [(control meta prior)] 'whizzy-send-prior)

      (local-set-key [?\C-c ?\C-w] 'whizzytex-mode)
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

as well as a tool bar menu `whizzy-mode-map'.
"
    (local-set-key [menu-bar whizzy] (cons "Whizzy" whizzy-mode-map))
    (local-set-key [C-next] 'whizzy-next-slice)
    (local-set-key [C-prior] 'whizzy-previous-slice) 

;     (local-set-key [C-M-home] 'whizzy-send-home)  
;     (local-set-key [C-M-end] 'whizzy-send-end)    
;     (local-set-key [C-M-next] 'whizzy-send-next)  
;     (local-set-key [C-M-prior] 'whizzy-send-prior)

    (local-set-key [?\C-c\C-w] 'whizzytex-mode)
    (local-set-key [C-return] 'whizzy-show-interaction))  
  )

(add-hook 'whizzytex-mode-hook 'whizzy-suggested-hook)

(defun whizzy-unset-options-hook ()
  (setq whizzy-error-report nil)
  (setq whizzy-auto-show-output nil)
)
  
;;;;

