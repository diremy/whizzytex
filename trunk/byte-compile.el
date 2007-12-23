(setq load-path (cons "." load-path))
(defvar whizzy-xemacsp (string-match "XEmacs" emacs-version)
  "Non-nil if we are running in the XEmacs environment.")
(defvar TeX-master nil)
(defvar iso-tex2iso-trans-tab nil)
;; does not exists in xemacs
(defun iso-tex2iso (x y) nil)
(if whizzy-xemacsp
    (progn
      (require 'overlay)
      (defun window-buffer-height (&optional window)))
  (defalias 'hyper-describe-function 'describe-function)
  ;; assumes version 21 or greater
  (defalias 'call-with-transparent-undo 'funcall)
) 

(cond
 ((equal 0 (string-match "20.*" emacs-version))
  (defvar whizzy-speed-string "?")
  (defvar whizzy-error-string nil)
  ;; those two should rather be part of the status--- to be fixed XXX
  (defvar whizzytex-mode-line-string
    (list " Whizzy" 
          'whizzy-error-string 
          "." 
          'whizzy-speed-string)))
 (t
  (defconst whizzy-error-string 27)
  (defconst whizzy-speed-string 28)
  (defvar whizzytex-mode-line-string
    (list " Whizzy" 
          '(:eval (whizzy-get whizzy-error-string)) 
          "." 
          '(:eval (whizzy-get whizzy-speed-string))))
  ))

(byte-compile-file "whizzytex.el")
