#|

This file is a part of NUMCL project.
Copyright (c) 2019 IBM Corporation
SPDX-License-Identifier: LGPL-3.0-or-later

NUMCL is free software: you can redistribute it and/or modify it under the terms
of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any
later version.

NUMCL is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
NUMCL.  If not, see <http://www.gnu.org/licenses/>.

|#

(in-package :numcl.impl)

;; size-increasing operations

;; concatenate

(defun numcl:concatenate (arrays &key (axis 0) out)
  (let* ((type (reduce #'union-to-float-type arrays :key #'array-element-type))
         (dims1 (shape (first arrays)))
         (axis (mod axis (length dims1)))
         (out (or out
                  (empty (append (subseq dims1 0 axis)
                                 (list (reduce #'+ arrays :key (lambda (array) (array-dimension array axis))))
                                 (subseq dims1 (1+ axis)))
                         :type type)))
         (arrays-simplified
          (iter (for a in arrays)
                (for dims = (shape a))
                (collecting
                 (reshape a (list (reduce #'* dims :start 0 :end axis)
                                  (elt dims axis)
                                  (reduce #'* dims :start (1+ axis)))))))
         (dims (shape out))
         (dims-before (reduce #'* dims :start 0 :end axis))
         (dims-after  (reduce #'* dims :start (1+ axis)))
         (simplified-dims (list dims-before
                                (elt dims axis)
                                dims-after))
         (out-simplified
          (reshape out simplified-dims)))

    
    (iter (for array in arrays-simplified)
          (for dim-axis = (array-dimension array 1))
          (iter (for i below dims-before)
                (iter (for j below dim-axis)
                      (iter (for k below dims-after)
                            (setf (aref out-simplified i (+ j sum) k)
                                  (%coerce (aref array i j k) type)))))
          (summing dim-axis into sum))
    out))

;; (concatenate (list (zeros '(2 2)) (ones '(2 2))))
;; (concatenate (list (zeros '(2 2)) (ones '(2 2))) :axis 0)
;; (concatenate (list (zeros '(2 2)) (ones '(2 2))) :axis 1)
;; (concatenate (list (zeros '(2 2)) (ones '(2 2))) :axis 2)

;; stack

(defun stack (arrays &key (axis 0) out)
  (let* ((type (reduce #'union-to-float-type arrays :key #'array-element-type))
         (dims1 (shape (first arrays)))
         (len (length arrays))
         ;; if len = 5, dims1 = '(2 2 2) and axis = -1 -> axis = 3, dims = '(2 2 2 5)
         ;; if len = 5, dims1 = '()      and axis = -1 -> axis = 0, dims = '(5)
         (axis (mod axis (1+ (length dims1))))
         (dims (append (subseq dims1 0 axis)
                       (list len)
                       (subseq dims1 axis)))
         (out (or out
                  (empty dims :type type)))
         (simplified-dims
          (list (reduce #'* dims1 :start 0 :end axis)
                (reduce #'* dims1 :start axis)))
         (arrays-simplified
          (iter (for a in arrays)
                (collecting
                 (reshape a simplified-dims))))
         (dims-before (reduce #'* dims :start 0 :end axis))
         (dims-after  (reduce #'* dims :start (1+ axis)))
         (simplified-dims (list dims-before
                                len
                                dims-after))
         (out-simplified
          (reshape out simplified-dims)))

    
    (iter (for array in arrays-simplified)
          (for dim-axis from 0)
          (iter (for i below dims-before)
                (iter (for k below dims-after)
                      (setf (aref out-simplified i dim-axis k)
                            (%coerce (aref array i k) type))))
          (summing dim-axis into sum))
    out))

;; (stack (list (zeros '(2 2)) (ones '(2 2))))
;; (stack (list (zeros '(2 2)) (ones '(2 2))) :axis 0)
;; (stack (list (zeros '(2 2)) (ones '(2 2))) :axis 1)
;; (stack (list (zeros '(2 2)) (ones '(2 2))) :axis 2)


;; different
#+(or)
(defun repeat (array n &key axis)
  (if (arrayp array)
      (if axis
          (concatenate (make-list n :initial-element array) :axis axis)
          (flatten
           (concatenate (make-list n :initial-element (reshape array `(,@(shape array) -1))) :axis -1)))
      (progn
        (assert (null axis))
        (full n array))))
