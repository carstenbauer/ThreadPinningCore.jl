import ThreadPinningCore:
    openblas_nthreads, openblas_getaffinity, openblas_getcpuid, openblas_getcpuids
import ThreadPinningCore: openblas_setaffinity, openblas_pinthread, openblas_pinthreads
using ..LibCalls: LibCalls, Ccpu_set_t

# querying
openblas_nthreads() = LibCalls.openblas_nthreads()

function openblas_getaffinity(; threadid, convert = true, juliathreadid = nothing)
    cpuset = Ref{Ccpu_set_t}()
    if isnothing(juliathreadid)
        ret = LibCalls.openblas_getaffinity(threadid - 1, sizeof(cpuset), cpuset)
    else
        ret = @fetchfrom juliathreadid LibCalls.openblas_getaffinity(
            threadid - 1,
            sizeof(cpuset),
            cpuset,
        )
    end
    if ret != 0
        throw(ErrorException("openblas_setaffinity returned a non-zero error code: $ret"))
    end
    return convert ? Base.convert(BitArray, cpuset[]) : cpuset[]
end

function openblas_getcpuid(; threadid, juliathreadid = Threads.threadid())
    mask = openblas_getaffinity(; threadid, juliathreadid)
    if sum(mask) == 1 # exactly one bit set
        return findfirst(mask) - 1
    else
        error(
            "The affinity mask of OpenBLAS thread $(threadid) includes multiple CPU " *
            "threads. This likely indicates that this OpenBLAS hasn't been pinned yet.",
        )
    end
end

function openblas_getcpuids(; kwargs...)
    nt = openblas_nthreads()
    cpuids = zeros(Int, nt)
    for threadid = 1:nt
        cpuids[threadid] = openblas_getcpuid(; threadid, kwargs...)
    end
    return cpuids
end

# pinning
function openblas_setaffinity(mask; threadid, juliathreadid = nothing)
    cpuset = Ccpu_set_t(mask)
    cpuset_ref = Ref{Ccpu_set_t}(cpuset)
    if isnothing(juliathreadid)
        LibCalls.openblas_setaffinity(threadid - 1, sizeof(cpuset), cpuset_ref)
    else
        ret = @fetchfrom juliathreadid LibCalls.openblas_setaffinity(
            threadid - 1,
            sizeof(cpuset),
            cpuset_ref,
        )
    end
    if ret != 0
        throw(ErrorException("openblas_setaffinity returned a non-zero error code: $ret"))
    end
    return
end

function openblas_pinthread(cpuid; threadid, juliathreadid = Threads.threadid())
    return openblas_setaffinity([cpuid]; threadid, juliathreadid)
end

function openblas_pinthreads(
    cpuids::AbstractVector{<:Integer};
    nthreads = openblas_nthreads(),
    juliathreadid = Threads.threadid(),
)
    # TODO: force / first_pin_attempt ?
    if nthreads > openblas_nthreads()
        throw(
            ArgumentError(
                "nthreads is too large. There are only $(openblas_nthreads()) OpenBLAS threads.",
            ),
        )
    end
    limit = min(length(cpuids), nthreads)
    for threadid = 1:limit
        openblas_pinthread(cpuids[threadid]; threadid, juliathreadid)
    end
    return
end
