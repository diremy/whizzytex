(setq load-path (cons "." load-path))
(defvar whizzy-xemacsp (string-match "XEmacs" emacs-version)
  "Non-nil if we are running in the XEmacs environment.")
(defvar TeX-master nil)
(if whizzy-xemacsp
    (progn
      (require 'overlay) 
      (defun window-buffer-height (&optional window)))
  (defalias 'hyper-describe-function 'describe-function)
  ;; assumes version 21 or greater
  (defalias 'call-with-transparent-undo 'funcall)
) 
(byte-compile-file "whizzytex.el")
