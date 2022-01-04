#lang racket

#|

Sliver - a generic slicing package for Racket

Copyright (c) 2022 by Jeffrey Massung
All rights reserved.

|#

(require racket/fixnum)
(require racket/flonum)
(require racket/function)
(require racket/generic)
(require racket/struct)

;; ----------------------------------------------------

(provide sliceable?
         slice
         slice-ref
         slice-length
         slice-range
         slice-materialize

         ; rename the structure
         (rename-out [slice%? slice?]
                     [slice%-of slice-of]
                     [slice%-start slice-start]
                     [slice%-end slice-end]))

;; ----------------------------------------------------

(define (sublist xs start end)
  (take (drop xs start) (- end start)))

;; ----------------------------------------------------

(define-generics sliceable
  (slice-ref sliceable i)
  (slice-length sliceable)
  (slice-range sliceable)
  (slice-materialize sliceable [start] [end])

  #:fast-defaults
  ([list?
    (define slice-ref list-ref)
    (define slice-length length)
    (define slice-range in-list)
    (define slice-materialize sublist)]
   [vector?
    (define slice-ref vector-ref)
    (define slice-length vector-length)
    (define slice-range in-vector)
    (define slice-materialize vector-copy)]
   [string?
    (define slice-ref string-ref)
    (define slice-length string-length)
    (define slice-range in-string)
    (define slice-materialize substring)]
   [bytes?
    (define slice-ref bytes-ref)
    (define slice-length bytes-length)
    (define slice-range in-bytes)
    (define slice-materialize subbytes)]
   [flvector?
    (define slice-ref flvector-ref)
    (define slice-length flvector-length)
    (define slice-range in-flvector)
    (define slice-materialize flvector-copy)]
   [fxvector?
    (define slice-ref fxvector-ref)
    (define slice-length fxvector-length)
    (define slice-range in-fxvector)
    (define slice-materialize fxvector-copy)]))

;; ----------------------------------------------------

(define (slice-guard xs start end type)
  (unless (sliceable? xs)
    (error type "~a is not sliceable?" xs))

  ; validate bounds
  (let ([n (slice-length xs)])
    (unless (<= 0 start end n)
      (error type "bounds [~a, ~a] outside of valid range [0, ~a]" start end n)))

  ; make the slice
  (values xs start end))

;; ----------------------------------------------------

(struct slice% (of start end)
  #:reflection-name 'slice
  #:guard slice-guard

  ; allow slices to be used in for loops
  #:property prop:sequence
  (λ (xs) (slice-range xs))

  ; custom printing of slices
  #:methods gen:custom-write
  [(define write-proc
     (make-constructor-style-printer
      (λ (xs) 'slice)
      (λ (xs) (list (slice-materialize xs)))))]
  
  ; implement slicing interface
  #:methods gen:sliceable
  [(define (slice-ref xs i)
     (slice%-ref xs i))
   (define (slice-length xs)
     (- (slice%-end xs)
        (slice%-start xs)))
   (define (slice-range xs)
     (slice%-range xs))
   (define (slice-materialize xs [start (slice%-start xs)] [end (slice%-end xs)])
     (slice%-materialize xs))])

;; ----------------------------------------------------

(define (slice%-ref xs i)
  (let ([n (sub1 (slice-length xs))])
    (if (<= 0 i n)
        (slice-ref (slice%-of xs) (+ (slice%-start xs) i))
        (error 'slice "index ~a outside of valid range [0, ~a]" i n))))

;; ----------------------------------------------------

(define (slice%-range xs)
  (let ([ys (slice%-of xs)]
        [refs (range (slice%-start xs) (slice%-end xs))])
    (if (list? ys)
        (sequence-map (λ (i x) x) (in-parallel refs ys))
        (sequence-map (λ (i) (slice-ref ys i)) refs))))

;; ----------------------------------------------------

(define (slice%-materialize xs)
  (slice-materialize (slice%-of xs) (slice%-start xs) (slice%-end xs)))

;; ----------------------------------------------------

(define (slice-of-list xs start end)
  (cond

    ; take-right requires traversing the list as well, but need to calculate end
    [(negative? start)
     (let ([n (length xs)])
       (slice-of-list xs (+ start n) end))]

    ; drop the first n elements from the list, decrement end position
    [(positive? start)
     (let ([ys (drop xs start)])
       (slice ys 0 (if (or (not end) (negative? end))
                       end
                       (- end start))))]

    ; slicing from start, nothing to do
    [else
     (slice xs start end)]))

;; ----------------------------------------------------

(define (slice xs [start 0] [end #f])
  (if (and (list? xs) (not (zero? start)))
      (slice-of-list xs start end)
      (let ([n (slice-length xs)])
        (cond
          [(not end)
           (slice xs start n)]
          [(negative? start)
           (slice xs (+ start n) end)]
          [(negative? end)
           (slice xs start (+ end n))]
          [else
           (if (slice%? xs)
               (let ([i (slice%-start xs)])
                 (slice (slice%-of xs) (+ start i) (+ end i)))
               (slice% xs start end))]))))
