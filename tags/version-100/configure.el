(defvar all nil)
(let ((dirs load-path)
      (dir)
      (home (regexp-quote (expand-file-name "~")))
      (one))
  (while (consp dirs)
    (setq dir (expand-file-name (car dirs)))
    (setq one nil)
    (cond
     ((string-match "\\(.*/whizzytex\\)" dir)
      (setq one (cons 0  (match-string 1 dir)))
      )
     ((string-match "\\(.*site-lisp\\).*" dir)
      (setq one (cons 1 (match-string 1 dir)))
      )
     ((string-match "\\(.*xemacs-packages/lisp\\).*" dir)
      (setq one (cons 2 (match-string 1 dir)))
      )
     ((string-match home dir)
      (setq one (cons 4 dir))
      )
     (t
      (message dir)
      )
     )
    (or
     (member one all)
     (null one)
     (if (file-directory-p (cdr one))
         (setq all (cons one all))
       (message one))
     )
    (setq dirs (cdr dirs))
    )
)
(defun compare (first second) (< (car first) (car second)))

(sort all 'compare)
(defun printall ()
  (while all
    (princ (cdar all))
    (princ "\n")
    (setq all (cdr all))))
