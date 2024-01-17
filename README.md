# CountFlops.jl

> :warning: **This was borrowed from https://github.com/triscale-innov/GFlops.jl.**

[![Build Status](https://github.com/charleskawczynski/CountFlops.jl/workflows/CI/badge.svg)](https://github.com/charleskawczynski/CountFlops.jl/actions)
[![Coverage](http://codecov.io/github/charleskawczynski/CountFlops.jl/coverage.svg?branch=master)](http://codecov.io/github/charleskawczynski/CountFlops.jl?branch=master)

When code performance is an issue, it is sometimes useful to get absolute
performance measurements in order to objectivise what is "slow" or
"fast". `CountFlops.jl` leverages the power of `Cassette.jl` to automatically count
the number of floating-point operations in a piece of code. When combined with
the accuracy of `BenchmarkTools`, this allows for easy and absolute performance
measurements.


## Installation

This package is registered and can therefore be simply be installed with

```julia
pkg> add CountFlops
```


## Example use

This simple example shows how to track the number of operations in a vector summation:
```julia
julia> using CountFlops

julia> x = rand(1000);

julia> @count_ops sum($x)
Flop Counter: 999 flop
┌─────┬─────────┐
│     │ Float64 │
├─────┼─────────┤
│ add │     999 │
└─────┴─────────┘
```

<br/>

`CountFlops.jl` internally tracks several types of Floating-Point operations, for
both 32-bit and 64-bit operands. Pretty-printing a Flop Counter only
shows non-zero entries, but any individual counter can be accessed:
```julia
julia> function mixed_dot(x, y)
           acc = 0.0
           @inbounds @simd for i in eachindex(x, y)
               acc += x[i] * y[i]
           end
           acc
       end
mixed_dot (generic function with 1 method)

julia> x = rand(Float32, 1000); y = rand(Float32, 1000);

julia> cnt = @count_ops mixed_dot($x, $y)
Flop Counter: 1000 flop
┌─────┬─────────┬─────────┐
│     │ Float32 │ Float64 │
├─────┼─────────┼─────────┤
│ add │       0 │    1000 │
│ mul │    1000 │       0 │
└─────┴─────────┴─────────┘

julia> fieldnames(CountFlops.Counter)
(:fma32, :fma64, :muladd32, :muladd64, :add32, :add64, :sub32, ...)

julia> cnt.add64
1000
```


## Caveats

### Fused Multiplication and Addition: FMA & MulAdd

On systems which support them, FMAs and MulAdds compute two operations (an
addition and a multiplication) in one instruction. `@count_ops` counts each
individual FMA/MulAdd as one operation, which makes it easier to interpret
counters. However, `@gflops` will count two floating-point operations for each
FMA, in accordance to the way high-performance benchmarks usually behave:

```julia
julia> x = 0.5; coeffs = rand(10);

# 9 MulAdds but 18 flop
julia> cnt = @count_ops evalpoly($x, $coeffs)
Flop Counter: 18 flop
┌────────┬─────────┐
│        │ Float64 │
├────────┼─────────┤
│ muladd │       9 │
└────────┴─────────┘
```

### Non-julia code

`CountFlops.jl` does not see what happens outside the realm of Julia code. It
especially does not see operations performed in external libraries such as BLAS
calls:

```julia
julia> using LinearAlgebra

julia> @count_ops dot($x, $y)
Flop Counter: 0 flop
```

This is a known issue; we'll try and find a way to circumvent the problem.
