import ThreadPinningCore:
    openblas_nthreads,
    openblas_getaffinity,
    openblas_getcpuid,
    openblas_getcpuids,
    openblas_ispinned,
    openblas_printaffinity,
    openblas_printaffinities,
    openblas_setaffinity,
    openblas_pinthread,
    openblas_pinthreads,
    openblas_unpinthread,
    openblas_unpinthreads

using ..LibCalls: LibCalls, Ccpu_set_t

# querying
openblas_nthreads() = LibCalls.openblas_nthreads()

function openblas_getaffinity(; threadid, convert = true, juliathreadid = nothing)
    if isfaking()
        cpuid = faking_openblas_getcpuid(; threadid)
        mask = BitArray(undef, length(faking_allowed_cpuids()))
        fill!(mask, 0)
        mask[cpuid+1] = 1
        return convert ? mask : Ccpu_set_t(mask)
    end
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

function openblas_printaffinity(; threadid, kwargs...)
    mask = openblas_getaffinity(; threadid, kwargs...)
    printmask(mask)
    return
end

function openblas_printaffinities(; kwargs...)
    for threadid = 1:openblas_nthreads()
        mask = openblas_getaffinity(; threadid, kwargs...)
        print(rpad("$(threadid):", 5))
        printmask(mask)
    end
    return
end

function openblas_getcpuid(; threadid, juliathreadid = Threads.threadid())
    if isfaking()
        if faking_openblas_ispinned(; threadid)
            return faking_openblas_getcpuid(; threadid)
        end
    else
        mask = openblas_getaffinity(; threadid, juliathreadid)
        if sum(mask) == 1 # exactly one bit set
            return findfirst(mask) - 1
        end
    end
    error(
        "The affinity mask of OpenBLAS thread $(threadid) includes multiple CPU " *
        "threads. This likely indicates that this OpenBLAS hasn't been pinned yet.",
    )
end

function openblas_getcpuids(; kwargs...)
    nt = openblas_nthreads()
    cpuids = zeros(Int, nt)
    for threadid = 1:nt
        cpuids[threadid] = openblas_getcpuid(; threadid, kwargs...)
    end
    return cpuids
end

function openblas_ispinned(; threadid, juliathreadid = Threads.threadid())
    if isfaking()
        return faking_openblas_ispinned(; threadid)
    end
    mask = openblas_getaffinity(; threadid, juliathreadid)
    return sum(mask) == 1 # exactly one bit set
end


# pinning
function openblas_setaffinity(mask; threadid, juliathreadid = nothing)
    if isfaking()
        if mask isa BitArray
            if sum(mask) > 1
                faking_openblas_setispinned(false; threadid)
                i = rand(findall(isone, mask))
            else
                faking_openblas_setispinned(true; threadid)
                i = findfirst(isone, mask)
            end
            cpuid = i - 1
        else
            cpuid = only(mask)
            faking_openblas_setispinned(true; threadid)
        end
        faking_openblas_setcpuid(cpuid; threadid)
        return
    end
    cpuset = Ccpu_set_t(mask)
    cpuset_ref = Ref{Ccpu_set_t}(cpuset)
    if isnothing(juliathreadid)
        ret = LibCalls.openblas_setaffinity(threadid - 1, sizeof(cpuset), cpuset_ref)
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

function openblas_unpinthread(; threadid::Integer)
    mask = trues(cpuidlimit())
    openblas_setaffinity(mask; threadid)
    return
end

function openblas_unpinthreads(; threadpool::Symbol = :default)
    mask = trues(cpuidlimit())
    for threadid = 1:openblas_nthreads()
        openblas_setaffinity(mask; threadid)
    end
    return
end
