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
(byte-compile-file "whizzytex.el")

(cond
 ((equal 0 (string-match "20.*" emacs-version))
  (defmacro whizzy-get-error-string () 'whizzy-error-string)
  (defmacro whizzy-get-speed-string () 'whizzy-speed-string)
  (defmacro whizzy-set-error-string (arg) 
    (list 'setq 'whizzy-error-string arg))
  (defmacro whizzy-set-speed-string (arg) 
    (list 'setq 'whizzy-speed-string arg))
  )
 (t
  (defmacro whizzy-get-error-string () 
    (list 'whizzy-get 'whizzy-error-string))
  (defmacro whizzy-get-speed-string () 
    (list 'whizzy-get 'whizzy-speed-string))
  (defmacro whizzy-set-error-string (arg) 
    (list 'whizzy-set 'whizzy-error-string arg))
  (defmacro whizzy-set-speed-string (arg) 
    (list 'whizzy-set 'whizzy-speed-string arg))
))
