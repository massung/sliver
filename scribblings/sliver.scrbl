#lang scribble/manual

@require[@for-label[sliver racket/base racket/class]]

@title{Sliver}
@author[@author+email["Jeffrey Massung" "massung@gmail.com"]]

@defmodule[sliver]

A generic slicing package for Racket.


@;; ----------------------------------------------------
@section{Sources}

The source code can be found at @url{https://github.com/massung/sliver}.


@;; ----------------------------------------------------
@section{Quick Example}

This is a brief example of slicing a string, which references the original instead of copying it. It's possible to slice any integer-indexable sequence (technically anything that implements the @racket[sliceable?] generic interface), which is any @racket[list?], @racket[vector?], @racket[string?], @racket[bytes?], @racket[flvector?], or @racket[fxvector?].

@racketblock[
 (define str "Hello, world!")

 ; slices can index using negative values as "from end"
 (define hello (slice str 0 5))
 (define world (slice str -6 -1))

 ; slices can be indexed
 (displayln (slice-ref world 2))

 ; slices are sequences and can use for loops and all sequence- functions
 (for ([c hello])
   (display (char-upcase c)))

 ; slices can be displayed, which materializes them (copies from source)
 (displayln hello)  ;=> Hello
 (displayln world)  ;=> world
]


@;; ----------------------------------------------------
@section{Introduction}

Slicing is the act of taking a linear sequence (e.g., a list or vector) of elements and referencing a sub-sequence in it without copying it out. Fundamentally, a slice is just a source sequence and start/end indices. This package attempts to also make slices a bit easier to work with by optimizing list access and adding referencing, sequencing, and iteration functionality.


@;; ----------------------------------------------------
@section{Slices}

The @racket[slice] function is used to create a new @racket[slice]:

@defproc[(slice [sliceable sliceable?]
                [start integer? 0]
                [end (or/c integer? #f) #f])
         slice?]{
 Creates and returns a new @racket[slice] of @racket[sliceable].

 The @racket[start] and @racket[end] arguments can be negative, in which case they are indexes from the end of the sequence.

 If @racket[end] is @racket[#f] then the slice will be from @racket[start] to the end of the sequence.
}

@defproc[(slice-ref [sliceable sliceable?]
                    [i exact-nonnegative-integer?])
         any/c]{
 Indexes into the slice to return the value at the given index reference. This index is bounds checked and cannot exceed the length of the slice.

 @racketblock[
  (slice-ref (slice "Hello, world!" 7 -1) 2)
  #\r
 ]
}

@defproc[(slice-length [sliceable sliceable?]) exact-nonnegative-integer?]{
 Returns the length of the slice.

 @racketblock[
  (slice-length (slice "Hello, world!" 7 -1))
  5
 ]
}

@defproc[(slice-range [sliceable sliceable?]) sequence?]{
 Returns the slice as a @racket[sequence?]. The @racket[slice] struct implements the @racket[prop:sequence] method, which calls this implicitly when needed for @racket[for] loops.

 @racketblock[
  (sequence-for-each display (slice "Hello, world!" 7 -1))
  world

  (for ([c (slice "Hello, world!" 7 -1)])
    (display c))
  world
 ]
}

@defproc[(slice-materialize [sliceable sliceable?]) sliceable?]{
 A @racket[slice] references the original source. Materializing a @racket[slice] copies the values from the original collection out into a new collection of the same type. Ideally this shouldn't need to be done very often.

 @racketblock[
  (slice-materialize (slice "Hello, world!" 0 5))  ;=> "Hello"
 ]
}


@;; ----------------------------------------------------
@section{Sliceable Generic Interface}


