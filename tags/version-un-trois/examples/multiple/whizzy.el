(defun whole ()
 (whizzy-after-save)
 (let ((name (file-name-sans-extension (buffer-file-name))))
   (shell-command (concat "make " name ".tex"))))
