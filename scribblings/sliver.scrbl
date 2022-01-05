#lang scribble/manual

@require[@for-label[sliver racket racket/base]]

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

 (code:comment "slices can index using negative values as 'from end'")
 (define hello (slice str 0 5))
 (define world (slice str -6 -1))

 (code:comment "slices can be indexed")
 (displayln (slice-ref world 2))

 (code:comment "slices are sequences and can use for loops and all sequence- functions")
 (for ([c hello])
   (display (char-upcase c)))

 (code:comment "slices can be displayed, which materializes them (copies from source)")
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

 If @racket[end] is @racket[#f] then the returned @racket[slice?] will default to the @racket[slice-length] of @racket[sliceable].
}

@defproc[(slice? [x any/c]) boolean?]{
 Returns @racket[#t] if @racket[x] is a @racket[slice?] structure. This is different from @racket[sliceable?], but all slices are also @racket[sliceable?].
}

@defproc[(slice-of [xs slice?]) sliceable?]{
 Returns the base @racket[sliceable?] collection @racket[xs] references. This is true even if @racket[xs] is a @racket[slice?] of a @racket[slice?] of a @racket[slice?] ....

 @racketblock[
  (slice-of (slice (slice "Hello, world!" 0 5) 1 -1))  (code:comment "\"Hello, world!\"")
 ]
}

@defproc[(slice-start [xs slice?]) exact-nonnegative-integer?]{
 Returns the aboslute start index of @racket[xs] given its underlying @racket[sliceable?] collection. As with @racket[slice-of], this is true regardless of how nested the @racket[slice?] is.

 @racketblock[
  (slice-start (slice (slice "Hello, world!" 2 8) 1 -1))  (code:comment "3")
 ]                                   
}

@defproc[(slice-end [xs slice?]) exact-nonnegative-integer?]{
 Returns the aboslute end index of @racket[xs] given its underlying @racket[sliceable?] collection. As with @racket[slice-of], this is true regardless of how nested the @racket[slice?] is.

 @racketblock[
  (slice-end (slice (slice "Hello, world!" 2 8) 1 -1))  (code:comment "7")
 ]                                   
}

@;; ----------------------------------------------------
@section{Sliceable Generic Interface}

The @racket[gen:sliceable] interface should be implemented for any integer-indexable collection. It consists of the above four methods: @racket[slice-ref], @racket[slice-length], @racket[slice-range], and @racket[slice-materialize].

The built-in Racket types @racket[list?], @racket[vector?], @racket[string?], @racket[bytes?], @racket[flvector?], and @racket[fxvector?] all implement these methods and so are both @racket[sliceable?] and also slices themselves.

While the interface is fairly straight-forward. The only "tricky" bit are the definitions of @racket[slice-materialize] and @racket[slice-copy]. These are implemented the way they are so that the @italic{type} of the underlying collection can determine how to materialize/copy a slice of itself, greatly simplifying the implementation of this package and allowing it to be extended to handle future types without knowing about them.

Generally speaking, @racket[slice-materialize] for a base type can simply be the @racket[identity] function, assuming the underlying type is immutable. Otherwise it could be implemented as a complete copy like so:

@racketblock[
 (define (slice-materialize xs)
   (slice-copy xs 0 (slice-length xs)))
]

The @racket[slice-copy] method - given the collection, start and exclusive-end range - should return a copied collection of the same type, however that is best achieved for the type itself.

Here is the definition of the @racket[get:sliceable] interface for @racket[vector?]:

@racketblock[
 [vector?
  (define slice-ref vector-ref)
  (define slice-length vector-length)
  (define slice-range in-vector)
  (define slice-materialize identity)
  (define slice-copy vector-copy)]
]

@defproc[(sliceable? [x any/c]) boolean?]{
 Returns @racket[#t] if @racket[x] implements the @racket[gen:sliceable] interface.
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

 The default implementation of this method for non-slice structures (e.g. lists, vectors, etc.) is simply the @racket[identity] function.
}

@defproc[(slice-copy [sliceable sliceable?]
                     [start exact-nonnegative-integer?]
                     [end (or/c exact-nonnegative-integer? #f) #f])
         sliceable?]{
 Returns a new @racket[sliceable?], which is of the same type as @racket[sliceable], but a copy of the extracted range instead of a reference. If @racket[end] is @racket[#f] then the copy is from @racket[start] to the end of the @racket[sliceable?] collection.

 It's rare to have to call this function. It exists as an abstraction around @racket[slice-materialize], which should be used to extract and copy sub-ranges instead.
}
