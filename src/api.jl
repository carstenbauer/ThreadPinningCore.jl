"""
Set the affinity of the calling Julia thread to the given CPU-threads.
"""
function setaffinity end

"""
Get an empty mask (to be used as input for [`setaffinity`](@ref)).
"""
function emptymask end

"""
Get the thread affinity of a thread. Returns the affinity mask as a vector of zeros and
ones.
By default, the mask is cut off at `Sys.CPU_THREADS`. This can be tuned via the
`cutoff` keyword argument (`nothing` means no cutoff).
"""
function getaffinity end

"Pin a thread to the given CPU thread."
function pinthread end

"Pin multiple threads to the given list of CPU threads."
function pinthreads end

"Check if a thread is pinned to a single CPU thread."
function ispinned end

"Get the id of the CPU thread a thread is currently running on."
function getcpuid end

"Get the ids of the CPU threads on which the Julia threads are currently running on."
function getcpuids end

"Print a mask in a compact way."
function printmask end

"Print the affinity of the calling thread."
function printaffinity end

"Get the IDs (`threadid()`) of the Julia threads, optionally of a given threadpool."
function threadids end

"""
Unpins the given Julia thread by setting the affinity mask to all unity.
Afterwards, the OS is free to move the Julia thread from one CPU thread to another.
"""
function unpinthread end

"""
Unpins all Julia threads by setting the affinity mask of all threads to all unity.
Afterwards, the OS is free to move any Julia thread from one CPU thread to another.
"""
function unpinthreads end

"""
Runs the function `f` with the specified pinning and restores the previous thread affinities
afterwards. Typically to be used in combination with do-syntax.

By default (`soft=false`), before the thread affinities are restored, the Julia
threads will be pinned to the CPU-threads they were running on previously.

**Example**
```julia
julia> ThreadPinningCore.getcpuids()
4-element Vector{Int64}:
  7
 75
 63
  4

julia> ThreadPinningCore.with_pinthreads(0:3) do
           ThreadPinningCore.getcpuids()
       end
4-element Vector{Int64}:
 0
 1
 2
 3

julia> ThreadPinningCore.getcpuids()
4-element Vector{Int64}:
  7
 75
 63
  4
```
"""
function with_pinthreads end



# OpenBLAS
"Number of OpenBLAS threads."
function openblas_nthreads end

"Query the affinity of an OpenBLAS thread"
function openblas_getaffinity end

"Get the id of the CPU thread a thread is currently running the given OpenBLAS thread."
function openblas_getcpuid end

"Get the ids of the CPU threads on which the OpenBLAS threads are currently running on."
function openblas_getcpuids end

"Check if the OpenBLAS thread is pinned to a single CPU thread."
function openblas_ispinned end

"Print the affinity of an OpenBLAS thread."
function openblas_printaffinity end

"Print the affinities of all OpenBLAS threads."
function openblas_printaffinities end

"""
Set the affinity of an OpenBLAS thread (`threadid`) to the given mask.

The input `mask` should be either of the following:
   * a `BitArray` indicating the mask directly
   * a vector of cpuids (the mask will be constructed automatically)
"""
function openblas_setaffinity end

"""
Pin an OpenBLAS thread to the given CPU ID.
"""
function openblas_pinthread end

"""
Pin OpenBLAS threads to the given CPU IDs.
"""
function openblas_pinthreads end

"""
Unpins the given OpenBLAS thread by setting the affinity mask to all unity.
Afterwards, the OS is free to move the OpenBLAS thread from one CPU thread to another.
"""
function openblas_unpinthread end

"""
Unpins all OpenBLAS threads by setting the affinity mask of all threads to all unity.
Afterwards, the OS is free to move any OpenBLAS thread from one CPU thread to another.
"""
function openblas_unpinthreads end
