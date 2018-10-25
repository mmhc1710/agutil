;;;; functions.lisp
;;;;
;;;; Copyright 2018 Alexander Gutev
;;;;
;;;; Permission is hereby granted, free of charge, to any person
;;;; obtaining a copy of this software and associated documentation
;;;; files (the "Software"), to deal in the Software without
;;;; restriction, including without limitation the rights to use,
;;;; copy, modify, merge, publish, distribute, sublicense, and/or sell
;;;; copies of the Software, and to permit persons to whom the
;;;; Software is furnished to do so, subject to the following
;;;; conditions:
;;;;
;;;; The above copyright notice and this permission notice shall be
;;;; included in all copies or substantial portions of the Software.
;;;;
;;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;;;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
;;;; OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;;;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;;;; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;;;; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;;;; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
;;;; OTHER DEALINGS IN THE SOFTWARE.

(in-package :agutil)


;;;; Macro-Writing Utilities

(defun gensyms (syms &key (key #'identity))
  "Returns a list of unique symbols, generated by GENSYM. The
   SYMBOL-NAME of each element in SYMS is used as a prefix of the
   corresponding generated symbol. If KEY is provided the SYMBOL-NAME
   of the result returned by calling KEY with each element in SYMS is
   used as the prefix."

  (mapcar (compose #'gensym #'symbol-name (curry #'funcall key)) syms))


;;;; Package Utilities

(defun merge-packages (new-package-name &rest packages)
  "Creates a new package with name NEW-PACKAGE-NAME, if it does not
   already exist, into which all external symbols in each package in
   PACKAGES are imported, by SHADOWING-IMPORT. The external symbols of
   each package in PACKAGES are imported in the order in which the
   package appears in the list, thus symbols imported from packages
   towards the end of the PACKAGES list will shadow symbols imported
   from packages at the beginning of the list."

  (flet ((merge-package (pkg)
	   (do-external-symbols (sym pkg)
	     (shadowing-import (list sym))
	     (export sym))))

    (let ((*package* (or (find-package new-package-name) (make-package new-package-name :use nil))))
      (mapc #'merge-package packages)
      *package*)))

(defmacro define-merged-package (name &rest packages)
  "Convenience macro which defines a merged package using
   MERGE-PACKAGES. NAME (not evaluated) is the name of the new package
   and PACKAGES (not evaluated) is the list of packages of which the
   external symbols are imported in package NAME."

  `(eval-when (:compile-toplevel :load-toplevel :execute)
     (apply #'merge-packages ',name ',packages)))



;;;; FIFO Queue

(defun make-queue (&rest elems)
  "Creates a FIFO queue with initial elements ELEMS."

  (let ((elems (copy-list elems)))
    (cons elems (last elems))))

(defun queue-empty? (queue)
  "Returns true if QUEUE is empty."
  (null (car queue)))

(defun enqueue (elem queue)
  "Adds ELEM to the head of QUEUE. QUEUE is modified."

  (let ((cell (cons elem nil)))
    (if (queue-empty? queue)
	(setf (car queue) cell)
	(setf (cddr queue) cell))

    (setf (cdr queue) cell)))

(defun dequeue (queue)
  "Removes and returns the element at the tail of QUEUE. NIL if the
   queue is empty. QUEUE is modified."

  (when (car queue)
    (prog1 (pop (car queue))
      (unless (car queue)
	(setf (cdr queue) nil)))))

(defun enqueue-list (elems queue)
  "Adds each element in the list ELEMS to the head of the queue
   QUEUE. QUEUE is modified."

  (dolist (elem elems)
    (enqueue elem queue)))

(defun queue->list (queue)
  "Returns a list of the elements in QUEUE."

  (car queue))


;;;; Utility Functions

(defun repeat-function (fn n)
  "Returns a list of N items obtained by repeatedly calling the
   function FN."

  (loop repeat n collect (funcall fn)))
