"""
    setaffinity(mask; threadid = Threads.threadid())

Set the affinity of the calling Julia thread to the given CPU-threads.
"""
function setaffinity end

"""
Get an empty mask (to be used as input for [`setaffinity`](@ref)).
"""
function emptymask end

"""
    getaffinity(; threadid = Threads.threadid(), cutoff = cpuidlimit())

Get the thread affinity of a thread. Returns the affinity mask as a vector of zeros and
ones.
By default, the mask is cut off at `Sys.CPU_THREADS`. This can be tuned via the
`cutoff` keyword argument (`nothing` means no cutoff).
"""
function getaffinity end

"""
    pinthread(cpuid::Integer; threadid = Threads.threadid())

Pin a thread to the given CPU thread.
"""
function pinthread end

"""
    pinthreads(cpuids;
        threadpool = :default,
        threadids = threadids(; threadpool),
        nthreads = nothing,
        force = true,
    )

Pin multiple threads to the given list of CPU threads.

The keyword argument `threadpool` indicates the considered thread pool (`:all` for all).
Alternatively, one may specify the `threadids` directly. The keyword argument `nthreads`
serves as a cutoff (`min(length(cpuids), nthreads)`). If `force=false`, threads are only
pinned if this is the very first pin attempt (otherwise is a no-op).
"""
function pinthreads end

"""
    ispinned(; threadid = Threads.threadid())

Check if a thread is pinned to a single CPU thread.
"""
function ispinned end

"""
    getcpuid(; threadid = nothing)

Get the id of the CPU thread a thread is currently running on.

If `threadid=nothing` (default), we query the id directly from the calling thread.
"""
function getcpuid end

"""
    getcpuids(; threadpool = :default)

Get the ids of the CPU threads on which the Julia threads are currently running on.
"""
function getcpuids end

"""
    printmask(mask; cutoff = cpuidlimit())

Print a mask in a compact way. By default, the mask is cut off after
`Sys.CPU_THREADS` elements.
"""
function printmask end

"""
    printaffinity(; threadid::Integer = Threads.threadid())

Print the affinity of the calling thread.
"""
function printaffinity end

"""
    threadids(; threadpool = :default)

Get the IDs (`Threads.threadid()`) of the Julia threads in the given threadpool.
"""
function threadids end

"""
    unpinthread(; threadid::Integer = Threads.threadid())

Unpins the given Julia thread by setting the affinity mask to all unity.
Afterwards, the OS is free to move the Julia thread from one CPU thread to another.
"""
function unpinthread end

"""
    unpinthreads(; threadpool::Symbol = :default)

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
julia> getcpuids()
4-element Vector{Int64}:
  7
 75
 63
  4

julia> with_pinthreads(0:3) do
           getcpuids()
       end
4-element Vector{Int64}:
 0
 1
 2
 3

julia> getcpuids()
4-element Vector{Int64}:
  7
 75
 63
  4
```
"""
function with_pinthreads end



# OpenBLAS
"Number of OpenBLAS threads. Should be the same as `BLAS.get_num_threads()` but calls into
libopenblas directly."
function openblas_nthreads end

"""
    openblas_getaffinity(; threadid, convert = true)

Query the affinity of the OpenBLAS thread with the given `threadid`
(typically `1:openblas_nthreads()`).
By default, returns a vector respresenting the mask.
If `convert=false` a `Ccpu_set_t` is returned instead.
"""
function openblas_getaffinity end

"""
    openblas_getcpuid(; threadid)

Get the id of the CPU thread on which the OpenBLAS thread with the given `threadid` is
running on **according to its affinity**.

**Note:** If the OpenBLAS thread has not been pinned before, this function will error
because the affinity mask highlights more than a single CPU thread by default.
"""
function openblas_getcpuid end

"Get the ids of the CPU threads on which the OpenBLAS threads are running on
**according to their affinity**. See [`openblas_getcpuid`](@ref) for more information."
function openblas_getcpuids end

"""
    openblas_ispinned(; threadid)

Check if the OpenBLAS thread is pinned to a single CPU thread.
"""
function openblas_ispinned end

"""
    openblas_printaffinity(; threadid)

Print the affinity of an OpenBLAS thread.
"""
function openblas_printaffinity end

"Print the affinities of all OpenBLAS threads."
function openblas_printaffinities end

"""
    openblas_setaffinity(mask; threadid)

Set the affinity of the OpenBLAS thread with the given `threadid` to the given `mask`.

The input `mask` should be one of the following:
   * a `BitArray` to indicate the mask directly
   * a vector of cpuids (in which case the mask will be constructed automatically)
"""
function openblas_setaffinity end

"""
    openblas_pinthread(cpuid; threadid)

Pin the OpenBLAS thread with the given `threadid` to the given CPU-thread (`cpuid`).
"""
function openblas_pinthread end

"""
    openblas_pinthreads(cpuids; nthreads = openblas_nthreads())

Pin the OpenBLAS threads to the given CPU IDs. The optional keyword argument `nthreads`
serves as a cutoff.
"""
function openblas_pinthreads end

"""
    openblas_unpinthread(; threadid)

Unpins the OpenBLAS thread with the given `threadid` by setting its affinity mask to all
unity. Afterwards, the OS is free to move the OpenBLAS thread from one CPU thread
to another.
"""
function openblas_unpinthread end

"""
    openblas_unpinthreads(; threadpool = :default)

Unpins all OpenBLAS threads by setting their affinity masks all unity.
Afterwards, the OS is free to move any OpenBLAS thread from one CPU thread to another.
"""
function openblas_unpinthreads end
