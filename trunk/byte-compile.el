(setq load-path (cons "." load-path))
(if (and (boundp 'running-xemacs) running-xemacs) 
    (progn (require 'overlay) 
           (defun window-buffer-height (&optional window))) 
  (defvar running-xemacs nil)) 
(byte-compile-file "whizzytex.el")
