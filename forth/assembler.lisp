(declaim (optimize (debug 3)))

;; parse program
(defun read-assembly-file (pathname)
  (let ((eof '#:eof) program)
    (with-open-file (stream pathname :direction :input)
      (loop (let ((form (read stream nil eof)))
              (when (eq form eof)
                (return))
              (push form program)))
      (nreverse program))))

;; SEGMENT - state of the assembler
(deftype assembly-unit () '(unsigned-byte 8))
(defclass segment ()
  ((%buffer :initarg :buffer :reader segment-buffer)
   (%label-map :accessor segment-label-map :initarg :label-map)
   (%index :accessor segment-index :initarg :index)
   (%user :accessor segment-user :initarg :user)))
(defun make-segment (&optional (buffer (make-array 0 :element-type 'assembly-unit
                                                     :adjustable t
                                                     :fill-pointer 0))
                               (label-map (make-hash-table))
		               (index 0)
		               user)
  (make-instance 'segment :buffer buffer :label-map label-map :index index :user user))

(defun emit-byte (segment byte)
  (vector-push-extend byte (segment-buffer segment))
  (incf (segment-index segment))
  (values))

(defun emit-label (segment label)
  (assert (not (gethash label (segment-label-map segment))))
  (setf (gethash label (segment-label-map segment))
        (segment-index segment)))

;; Define instruction machinery
(let ((instruction-emitters (make-hash-table)))
  (defun %define-instruction-emitter (name function)
    (setf (gethash name instruction-emitters) function))
  (defun instruction-emitter-function (name)
    (gethash name instruction-emitters)))

;; more options to be defined here... more general than necessary for now
(defmacro define-instruction (name lambda-list &rest options)
  (let ((option-spec (first options)))
    (multiple-value-bind (option args)
        (if (consp option-spec)
            (values (first option-spec) (rest option-spec))
            (values option-spec nil))
      (ecase option
        (:emitter `(%define-instruction-emitter ',name (lambda ,lambda-list ,@args)))))))

;; register
(defparameter +register-encoding-map+
  #(%r0 %r1 %r2 %r3 %r4 %r5 %r6 %r7 %r8 %r9 %r10 %r11 %r12 %r13 %r14 %r15))

(deftype register-encoding () '(unsigned-byte 4))
(defun registerp (register)
  (find register +register-encoding-map+))
(defun register-encoding (register)
  (assert (registerp register) (register))
  (position register +register-encoding-map+))
(deftype immediate () 'integer)
(defun immediatep (x) (typep x 'immediate))

(defmacro define-instruction-format ((name total-size) &rest slot-specs)
  (let ((args (mapcar #'first (remove-if (lambda (x) (member :value x)) slot-specs))))
    (alexandria:with-unique-names (nbytes bytes segment)
      `(defun ,(alexandria:symbolicate "EMIT-" name) ,args
         (declare (unsigned-byte ,@args))
         (let ((,nbytes (floor ,total-size 8))
               (,bytes 0))
           ,@(mapcar (lambda (slot-spec)
                       (destructuring-bind (name &key field value)
                           slot-spec
                         `(setf (ldb ,field ,bytes) ,(or value name))))
                     slot-specs)
           (let ((,segment *segment*))
             (loop for i from 0 below (* ,nbytes 8) by 8
                   do (emit-byte ,segment (ldb (byte 8 i) ,bytes))))
           ,bytes)))))

;;;; machine
(defvar *segment*)

(defun relativize (absolute-address)
  (- absolute-address (segment-index *segment*)))

(defun relativep (address)
  (when (and (consp address) (eq (first address) 'relative))
    (unless (= (length address) 2)
      (error "incorrect arity for relative"))
    t))

(define-instruction-format (simple 8)
  (unused :field (byte 3 5) :value #b000)
  (opcode :field (byte 1 4))
  (arg    :field (byte 4 0)))

(define-instruction-format (two-byte 16)
  (unused :field (byte 1 7) :value #b0)
  (opcode :field (byte 3 4))
  (arg2   :field (byte 4 0))
  
  (arg3   :field (byte 4 12))
  (arg1   :field (byte 4 8)))

(define-instruction-format (two-byte* 16)
  (unused :field (byte 1 7) :value #b0)
  (opcode :field (byte 4 3))
  (unused :field (byte 3 0) :value #b000)
  
  (arg1 :field (byte 4 12))
  (arg2 :field (byte 4 8)))

(define-instruction-format (three-byte 24)
  (opcode :field (byte 4 4))
  (reg    :field (byte 4 0))
  
  (imm    :field (byte 16 8)))

(define-instruction-format (four-byte 32)
  (opcode  :field (byte 4 4))
  (unused  :field (byte 4 0) :value #b0000)
  
  (reg1    :field (byte 4 12))
  (reg/imm :field (byte 4 8))
  
  (imm16   :field (byte 16 16)))

(define-instruction-format (word 16)
  (word :field (byte 16 0)))

(define-instruction push (reg)
  (:emitter (emit-simple 0 (register-encoding reg))))

(define-instruction pop (reg)
  (:emitter (emit-simple 1 (register-encoding reg))))

(define-instruction call (base offset)
  (:emitter (emit-three-byte #b1001 (register-encoding base)
                             (immediate (if (relativep offset)
                                            (- (relativize (second offset)) 3)
                                            offset)))))

(define-instruction add (dest arg)
  (:emitter (if (registerp arg)
                (emit-two-byte* #b0110 (register-encoding dest) (register-encoding arg))
                (emit-three-byte #b0111 (register-encoding dest) (immediate arg)))))

(macrolet ((def (name opcode)
             `(define-instruction ,name (dest arg)
                (:emitter (emit-two-byte* ,opcode (register-encoding dest) (register-encoding arg))))))
  (def addc #b0111)
  (def sub #b1000)
  (def subc #b1001))

(macrolet ((def (name ropcode iopcode)
             `(define-instruction ,name (dest arg)
                (:emitter (if (registerp arg)
                              (emit-two-byte* ,ropcode (register-encoding dest) (register-encoding arg))
                              (emit-two-byte* ,iopcode (register-encoding dest) (immediate arg)))))))
  (def rot #b1010 #b1100)
  (def rotc #b1011 #b1101))

(macrolet ((def (name opcode)
             `(define-instruction ,name (reg base address)
                (:emitter (emit-four-byte ,opcode (register-encoding reg)
                                          (register-encoding base)
                                          (immediate (if (relativep address)
                                                         (- (relativize (second address)) 4)
                                                         address)))))))
  (def bez #b1011)
  (def bnez #b1100)
  (def bgez #b1101))

(define-instruction mov (dest src)
  (:emitter (if (immediatep src)
                (emit-three-byte #b1000 (register-encoding dest) (immediate src))
                (if (and (registerp dest) (registerp src))
                    (emit-two-byte #b010 (register-encoding dest) (register-encoding src)
                                   #b1010)
                    (multiple-value-bind (base offset)
                      (parse-memory-reference (if (registerp dest) src dest))
                      (if (registerp dest)
                          (emit-four-byte #b1110 (register-encoding dest)
                                          (register-encoding base)
                                          (immediate offset))
                          (emit-four-byte #b1111 (register-encoding base)
                                          (register-encoding src)
                                          (immediate offset))))))))

(define-instruction lfun (arg1 arg2 arg3)
  (:emitter (if (immediatep arg3)
                (emit-four-byte #b1010 (register-encoding arg2)
                                (immediate arg1) (immediate arg3))
                (emit-two-byte #b010 (register-encoding arg2)
                               (register-encoding arg3) (immediate arg1)))))

(define-instruction nop ()
  (:emitter (emit-byte *segment* #x6000)))

(defun immediate (immediate)
  (check-type immediate immediate)
  (if (minusp immediate) (+ (expt 2 16) immediate) immediate))

(defun memory-reference-p (x)
  (and (listp x) (eq (first x) '@+)))

(defun check-memory-reference-syntax (memory-reference)
  (unless (memory-reference-p memory-reference)
    (error "Not valid memory-reference syntax")))

(defun parse-memory-reference (memory-reference)
  (check-memory-reference-syntax memory-reference)
  (values (find-if #'registerp (rest memory-reference))
          (find-if #'immediatep (rest memory-reference))))

;; emit instruction to segment
(defun emit-inst (instruction &rest args)
  (apply (instruction-emitter-function instruction) args))

;; assembler
;; labels support
(defun labelp (x)
  (and (symbolp x) (not (eq x '@+)) (not (eq x 'relative)) (not (registerp x))))

(defparameter +assembler-directive-map+ (make-hash-table))
(defun directivep (x)
  (directive-action x))
(defun directive-action (x)
  (gethash x +assembler-directive-map+))
(defmacro define-directive (name action)
  `(setf (gethash ',name +assembler-directive-map+)
	 (lambda (compute-labels-p args)
	   (declare (ignorable compute-labels-p args))
	   ,action)))

(define-directive .label
    (when compute-labels-p (emit-label *segment* (first args))))
(define-directive .print
    (print (resolve-labels compute-labels-p (first args))))
(define-directive .annotate
    nil)
(define-directive .word
    (dolist (number (resolve-labels compute-labels-p args))
      (emit-word (if (< number 0) (+ number 65536) number))))

(defun resolve-labels (compute-labels-p arg)
  (if (labelp arg)
      (if compute-labels-p
	  0
	  (let ((address (gethash arg (segment-label-map *segment*))))
	    (assert (numberp address))
	    address))
      (if (atom arg)
	  arg
	  (mapcar (alexandria:curry #'resolve-labels compute-labels-p) arg))))

(defun emit-instructions (instructions compute-labels-p &optional (*segment* *segment*))
  (setf (segment-user *segment*) nil)
  (dolist (instruction instructions)
    (let ((op (first instruction)) (args (rest instruction)))
      (if (directivep op)
	  (funcall (directive-action op) compute-labels-p args)
	  (apply #'emit-inst op (resolve-labels compute-labels-p args))))))

(defun assemble (segment instructions &aux (*annotate* nil))
  ;; compute the label map first, by copying the buffer to a new segment
  ;; while sharing the label map, so the old buffer remains in
  ;; the original segment to avoid backpatching label addresses
  (emit-instructions instructions t (make-segment (alexandria:copy-array (segment-buffer segment))
						  (segment-label-map segment)))
  (emit-instructions instructions nil segment)
  segment)

(defun assemble-file (instructions binary-file)
  (with-open-file (stream binary-file :direction :output
                                      :element-type '(unsigned-byte 8)
                                      :if-exists :supersede)
    (write-sequence (segment-buffer (assemble (make-segment) instructions))
                    stream)))

(defun assemble-file-mif (instructions mif-file &optional label-info-file)
  (with-open-file (stream mif-file :direction :output
                                   :if-exists :supersede)
    (let* ((segment (assemble (make-segment) instructions))
	   (buffer (segment-buffer segment))
	   (label-map (segment-label-map segment)))
      (dotimes (i (fill-pointer buffer))
        (format stream "~8,'0b~%" (aref buffer i)))
      (when label-info-file
	(with-open-file (label-stream label-info-file :direction :output :if-exists :supersede)
	  (dolist (key (alexandria:hash-table-keys label-map))
	    (format label-stream "0x~4,'0x ~a~%" (gethash key label-map) (symbol-name key))))))))
