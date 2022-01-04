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

;; ----------------------------------------------------

(provide sliceable?
         slice
         slice-ref
         slice-length
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
  (slice-materialize sliceable [start] [end])

  #:fast-defaults
  ([list?
    (define slice-ref list-ref)
    (define slice-length length)
    (define slice-materialize sublist)]
   [vector?
    (define slice-ref vector-ref)
    (define slice-length vector-length)
    (define slice-materialize vector-copy)]
   [string?
    (define slice-ref string-ref)
    (define slice-length string-length)
    (define slice-materialize substring)]
   [bytes?
    (define slice-ref bytes-ref)
    (define slice-length bytes-length)
    (define slice-materialize subbytes)]
   [flvector?
    (define slice-ref flvector-ref)
    (define slice-length flvector-length)
    (define slice-materialize flvector-copy)]
   [fxvector?
    (define slice-ref fxvector-ref)
    (define slice-length fxvector-length)
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
  (λ (xs)
    (let ([proc ((curry slice%-ref) xs)])
      (sequence-map proc (in-range (slice-length xs)))))

  ; custom printing of slices
  #:methods gen:custom-write
  [(define (write-proc xs port mode)
     (write-string "'#<slice:" port)
     (for ([x xs])
       (write-char #\space port)
       (write x port))
     (write-string ">" port))]
  
  ; implement slicing interface
  #:methods gen:sliceable
  [(define (slice-ref xs i)
     (slice%-ref xs i))
   (define (slice-length xs)
     (- (slice%-end xs)
        (slice%-start xs)))
   (define (slice-materialize xs [start (slice%-start xs)] [end (slice%-end xs)])
     (slice%-materialize xs))])

;; ----------------------------------------------------

(define (slice%-ref xs i)
  (let ([n (sub1 (slice-length xs))])
    (if (<= 0 i n)
        (slice-ref (slice%-of xs) (+ (slice%-start xs) i))
        (error 'slice "index ~a outside of valid range [0, ~a]" i n))))

;; ----------------------------------------------------

(define (slice%-materialize xs)
  (slice-materialize (slice%-of xs) (slice%-start xs) (slice%-end xs)))

;; ----------------------------------------------------

(define (slice xs start [end #f])
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
           (slice% xs start end))])))
