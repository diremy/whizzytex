(setq load-path (cons "." load-path))
(if (and (boundp 'running-xemacs) running-xemacs) 
    (progn
      (require 'overlay) 
      (defun window-buffer-height (&optional window))) 
  (defvar running-xemacs nil)
  (defalias 'hyper-describe-function 'describe-function)
) 
(byte-compile-file "whizzytex.el")
