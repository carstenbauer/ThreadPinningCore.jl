# ThreadPinningCore

[![Build Status](https://github.com/carstenbauer/ThreadPinningCore.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/carstenbauer/ThreadPinningCore.jl/actions/workflows/CI.yml?query=branch%3Amain)

This package will be a backend of [ThreadPinning.jl](https://github.com/carstenbauer/ThreadPinning.jl). You may use it directly as a more lightweight alternative. Note, however, that you will need to specify the CPU threads - to which the Julia threads should be pinned - by OS indices ("physical" indices).

## Features

* Pin Julia threads (get and set their processor affinity)
* Pin OpenBLAS threads (get and set their processor affinity)
* Fake mode (pin threads without actually pinning them, to be used in conjuction with [SysInfo.jl](https://github.com/carstenbauer/SysInfo.jl)'s `TestSystem`s)
* ...

## Supported operating systems

**Only Linux is fully and officially supported.** However, you can install and load the package (`using ThreadPinningCore`) without any issues on all operating systems. It's only when you call (most) functions that you will see error messages.

## Usage
```julia-repl
julia> using ThreadPinningCore

julia> ThreadPinningCore.getcpuid() # where the calling thread is currently running
232

julia> ThreadPinningCore.ispinned() # single CPU thread affinity?
false

julia> ThreadPinningCore.printaffinity()
1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

julia> ThreadPinningCore.pinthread(4) # pin to the CPU thread with ID 4 ("physical" OS ordering, not logical)

julia> ThreadPinningCore.getcpuid()
4

julia> ThreadPinningCore.printaffinity()
0000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

julia> ThreadPinningCore.ispinned()
true
```

## API

See [api.jl](src/api.jl) and the `@public`/`export` markers in [ThreadPinningCore.jl](https://github.com/carstenbauer/ThreadPinningCore.jl/blob/main/src/ThreadPinningCore.jl).
