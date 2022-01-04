# Sliver

Sliver is a generic slicing implementation for [Racket][racket].


## Installation

Installing should be as simple as using `raco` from the command line:

```zsh
% raco pkg install sliver
```

After the above, you should be able to `(require sliver)` and begin working!

## What are Slices?

Slices are offsets and lengths (subsets) into larger collections of data. 

For example, you may have a vector of 1M values and wish to work on them in chunks of 1000 values. Instead of creating 1000 new vectors of 1000 items each (using `vector-copy`) or using indexes manually to navigate around, you can use slices:

```racket
(define large-vector (make-vector 1000000))

(define slices
  (for/list ([i 1000])
    (let* ([start (* i 1000)]
           [end   (+ start 1000)])
      (slice large-vector start end))))
```

Each of the 1000 `slices` created is simply a reference to the original `large-vector`.

Slices can then be indexed (with bounds checking), iterated over (they are sequences), be sliced themselves, and even materialized into a copy.

## Creating Slices

Slices can be made using the `slice` function:

```racket
(slice seq start [end #f])
```

The `seq` parameter is the source data type which can be any integer-indexable sequence.

The `start` and `end` parameters can be positive _or negative_ integers (negative indexes are “from the end”). If `end` is `#f` then it defaults to the end of the input sequence.

For example:

```racket
(slice "abcdefg" 2 -2)
```

## The `gen:sliceable` Interface

Sliver defines the `gen:sliceable` interface, which declares three methods for interfacing with slices:

* `slice-ref` is used to fetch a slice value by index
* `slice-length` is used to return the length of the slice
* `slice-materialize` is used to copy the slice from its source

Because `gen:sliceable` is a generic interface, all basic Racket sequences are also slices:

```racket
(slice-ref '(0 1 2 3 4) 2)  ;=> 2
(slice-ref #(0 1 2 3 4) 2)  ;=> 2
(slice-ref "01234" 2)       ;=> #\2
(slice-ref #"01234" 2)      ;=> 50
```

The `slice` struct also implements `prop:sequence`, and can therefore be used in `for` loops and for all `sequence-` functions:

```racket
(for ([x (slice '(0 1 2 3 4 5 6 7) 2 -2)])
  (displayln x))
2
3
4
5

(sequence-for-each displayln (slice "abcdefg" 2 -2))
c
d
e
```

## Algorithmic Complexity

The complexity of `slice-ref` is always based on the complexity of the underlying data type. So, for the slice of a list it will be O(N), but for all others it will be O(1). 

The complexity of `slice-length` is always O(1) as the value is simply computed from the start and end values of the slice.

The complexity of `slice-materialize` is O(N) as it is extracting a copy from the original data structure.

## Documenation

Refer to the [scribble documentation][docs].

## License

This code is licensed under the MIT license. See the LICENSE.txt file in this repository for the complete text.

[racket]: https://racket-lang.org/
[docs]: https://docs.racket-lang.org/sliver/index.html
