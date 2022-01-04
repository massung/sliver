#lang racket

#|

Sliver - a generic slicing package for Racket

Copyright (c) 2022 by Jeffrey Massung
All rights reserved.

|#

(require rackunit)

;; ----------------------------------------------------

(require "../main.rkt")

;; ----------------------------------------------------

(define test-list '(0 1 2 3 4 5 6 7 8 9))
(define test-vector #(0 1 2 3 4 5 6 7 8 9))
(define test-string "0123456789")
(define test-bytes #"0123456789")

;; ----------------------------------------------------

(define (sos xs)  ; slice of slice
  (slice xs 1 -1))

;; ----------------------------------------------------

(define (test-slice xs start [end #f])
  (slice-materialize (slice xs start end)))

;; ----------------------------------------------------

(define (test-slices start end pairs)
  (for ([test-pair pairs])
    (match test-pair
      [(list seq result)
       (check-equal? (test-slice seq start end) result)])))

;; ----------------------------------------------------

(test-case "Slicing to end"
           (test-slices 3 #f `((,test-list ,(drop test-list 3))
                               (,test-vector ,(vector-drop test-vector 3))
                               (,test-string ,(substring test-string 3))
                               (,test-bytes ,(subbytes test-bytes 3)))))

;; ----------------------------------------------------

(test-case "Slicing with end"
           (test-slices 3 6 `((,test-list ,(take (drop test-list 3) 3))
                              (,test-vector ,(vector-copy test-vector 3 6))
                              (,test-string ,(substring test-string 3 6))
                              (,test-bytes ,(subbytes test-bytes 3 6)))))

;; ----------------------------------------------------

(test-case "Slicing from end"
           (test-slices 3 -2 `((,test-list ,(take (drop test-list 3) 5))
                              (,test-vector ,(vector-copy test-vector 3 8))
                              (,test-string ,(substring test-string 3 8))
                              (,test-bytes ,(subbytes test-bytes 3 8)))))

;; ----------------------------------------------------

(test-case "Slicing starting from end"
           (test-slices -5 -2 `((,test-list ,(take (drop test-list 5) 3))
                                (,test-vector ,(vector-copy test-vector 5 8))
                                (,test-string ,(substring test-string 5 8))
                                (,test-bytes ,(subbytes test-bytes 5 8)))))

;; ----------------------------------------------------

(test-case "Slicing slices"
           (test-slices -5 -2 `((,(sos test-list) (4 5 6))
                                (,(sos test-vector) #(4 5 6))
                                (,(sos test-string) "456")
                                (,(sos test-bytes) #"456"))))

;; ----------------------------------------------------

(test-case "Slices as sequences"
           (check-equal? (for/list ([x (slice test-vector 3 -4)]) x) '(3 4 5))
           (check-equal? (for/vector ([x (slice test-list 3 -4)]) x) #(3 4 5)))
