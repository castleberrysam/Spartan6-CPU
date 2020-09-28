(load (merge-pathnames "assembler.lisp" *load-truename*))

(defun emit-forth-string (string &optional (flags 0))
  (assert (stringp string))
  (emit-byte *segment* (logior (length string) flags))
  (dotimes (i (length string))
    (emit-byte *segment* (char-code (char string i)))))

(define-directive .fstring
    (let ((string (first args)) (flags (second args)))
      (unless flags (setf flags 0))
      (emit-forth-string string flags)))

(defun get-vocab-map ()
  (if (segment-user *segment*)
      (segment-user *segment*)
      (progn
	(setf (segment-user *segment*) (make-hash-table))
	(segment-user *segment*))))
(defun get-vocab-ptr (vocab)
  (let ((ptr (gethash vocab (get-vocab-map))))
    (if ptr ptr 0)))
(defun add-to-vocab (vocab addr)
  (setf (gethash vocab (get-vocab-map)) addr))

(define-directive .defword
    (let* ((token (first args)) (name (symbol-name token))
	   (vocab (second args)) (tags (rest (rest args)))
	   (old-vocab-ptr (get-vocab-ptr vocab)) (flags 0))
      (assert (< (length name) 32))
      (dolist (tag tags)
	(ecase tag
	  (:immediate (incf flags #x80))))
      (add-to-vocab vocab (segment-index *segment*))
      (emit-forth-string name flags)
      (emit-word old-vocab-ptr)
      (when compute-labels-p (emit-label *segment* token))))

(define-directive .vocabptr
    (emit-word (get-vocab-ptr (first args))))
