(setq load-path (cons "." load-path))
(defvar whizzy-xemacsp (string-match "XEmacs" emacs-version)
  "Non-nil if we are running in the XEmacs environment.")
(if whizzy-xemacsp
    (progn
      (require 'overlay) 
      (defun window-buffer-height (&optional window)))
  (defalias 'hyper-describe-function 'describe-function)
) 
(byte-compile-file "whizzytex.el")
