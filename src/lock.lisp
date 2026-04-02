(defpackage #:coalton-threads/lock
  (:use #:coalton #:coalton-prelude)
  (:import-from #:coalton-library/system #:LispCondition)
  (:export
   #:Lock
   #:with-lock-held
   #:new
   #:acquire
   #:acquire-no-wait
   #:release))
(in-package #:coalton-threads/lock)
(named-readtables:in-readtable coalton:coalton)

(coalton-toplevel
  (repr :native bt2:lock)
  (define-type Lock
    "Wrapper for a native non-recursive lock.")

  (declare new (Void -> Lock))
  (define (new)
    "Creates a non-recursive lock."
    (lisp (-> Lock) ()
      (bt2:make-lock)))

  (declare acquire (Lock -> Boolean))
  (define (acquire lock)
    "Acquire `lock' for the calling thread."
    (lisp (-> Boolean) (lock)
      (bt2:acquire-lock lock)))

  (declare acquire-no-wait (Lock -> Boolean))
  (define (acquire-no-wait lock)
    "Acquire `lock' for the calling thread.
Returns Boolean immediately, True if `lock' was acquired, False otherwise."
    (lisp (-> Boolean) (lock)
      (bt2:acquire-lock lock :wait nil)))

  (declare release (Lock -> (Result LispCondition Lock)))
  (define (release lock)
    "Release `lock'. It is an error to call this unless
the lock has previously been acquired (and not released) by the same
thread. If other threads are waiting for the lock, the
`acquire-lock' call in one of them will now be able to continue.

Returns the lock."
    (lisp (-> Result LispCondition Lock) (lock)
      (cl:handler-case (Ok (bt2:release-lock lock))
        (cl:error (c) (Err c)))))

  (declare with-lock-held (Lock * (Void -> :a) -> :a))
  (define (with-lock-held lock thunk)
    (acquire lock)
    (let ((result (thunk)))
      (release lock)
      result)))
