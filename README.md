# ThreadPinningCore

[![Build Status](https://github.com/carstenbauer/ThreadPinningCore.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/carstenbauer/ThreadPinningCore.jl/actions/workflows/CI.yml?query=branch%3Amain)

This package will be a backend of [ThreadPinning.jl](https://github.com/carstenbauer/ThreadPinning.jl). You may use it directly as a more lightweight alternative. Note, however, that you will need to specify the CPU threads - to which the Julia threads should be pinned - by OS indices ("physical" indices).

## Supported operating systems

**Only Linux is fully and officially supported.** However, you can install and load the package (`using ThreadPinningCore`) without any issues on all operating systems. It's only when you call functions that you will see error messages.

## Usage
```julia-repl
julia> using ThreadPinningCore

julia> getcpuid() # where the calling thread is currently running
232

julia> ispinned() # single CPU thread affinity?
false

julia> printaffinity()
1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

julia> pinthread(4) # pin to the CPU thread with ID 4 ("physical" OS ordering, not logical)

julia> getcpuid()
4

julia> printaffinity()
0000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

julia> ispinned()
true
```
