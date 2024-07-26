module Internals

import ThreadPinningCore:
    ThreadPinningCore,
    getaffinity,
    pinthread,
    ispinned,
    getcpuid,
    getcpuids,
    printmask,
    printaffinity,
    threadids,
    pinthreads,
    setaffinity,
    emptymask,
    unpinthread,
    unpinthreads,
    with_pinthreads,
    ncputhreads

using StableTasks: @fetchfrom

using ..LibCalls:
    jl_setaffinity,
    jl_getaffinity,
    uv_thread_getaffinity,
    uv_thread_setaffinity,
    uv_cpumask_size,
    sched_getcpu

include("globals.jl")

# generic
ncputhreads() = isfaking() ? length(faking_allowed_cpuids()) : Sys.CPU_THREADS

function emptymask()
    if isfaking()
        return zeros(Cchar, ncputhreads())
    end
    masksize = uv_cpumask_size()
    if masksize < 0
        throw(ErrorException("Libuv returned an invalid mask size. Unsupported OS?"))
    end
    mask = zeros(Cchar, masksize)
    return mask
end

printmask(mask; kwargs...) = printmask(stdout, mask; kwargs...)
function printmask(io, mask; cutoff = ncputhreads())
    for i = 1:cutoff
        print(io, Int(mask[i]))
    end
    print("\n")
end

# querying
function threadids(; threadpool = :default)
    if threadpool == :default
        return Threads.nthreads(:interactive) .+ (1:Threads.nthreads(:default))
    elseif threadpool == :interactive
        return 1:Threads.nthreads(:interactive)
    elseif threadpool == :all
        return 1:(Threads.nthreads(:interactive)+Threads.nthreads(:default))
    else
        throw(
            ArgumentError(
                "Unknown value for `threadpool` keyword argument. " *
                "Supported values are `:all`, `:default`, and " *
                "`:interactive`.",
            ),
        )
    end
end

function getaffinity(;
    threadid::Integer = Threads.threadid(),
    cutoff::Union{Integer,Nothing} = ncputhreads(),
)
    if isfaking()
        cpuid = faking_getcpuid(; threadid)
        mask = emptymask()
        mask[cpuid+1] = 1
        return isnothing(cutoff) ? mask : mask[1:cutoff]
    end
    @static if VERSION > v"1.11-"
        c_threadid = threadid - 1
        masksize = uv_cpumask_size()
        mask = zeros(Cchar, masksize)
        ret = jl_getaffinity(c_threadid, mask, masksize)
        if !iszero(ret)
            throw(ErrorException("Couldn't query the affinity on this system."))
        end
    else
        mask = uv_thread_getaffinity(threadid)
    end
    return isnothing(cutoff) ? mask : mask[1:cutoff]
end

printaffinity(; threadid::Integer = Threads.threadid()) = printmask(getaffinity(; threadid))

function getcpuid(; threadid::Union{Integer,Nothing} = nothing)
    if isfaking()
        return faking_getcpuid(;
            threadid = isnothing(threadid) ? Threads.threadid() : threadid,
        )
    end
    if isnothing(threadid)
        sched_getcpu()
    else
        @fetchfrom threadid sched_getcpu()
    end
end

function getcpuids(; threadpool = :default)::Vector{Int}
    if !(threadpool in (:all, :default, :interactive))
        throw(
            ArgumentError(
                "Unknown value for `threadpool` keyword argument. " *
                "Supported values are `:all`, `:default`, and " *
                "`:interactive`.",
            ),
        )
    end
    tids_pool = ThreadPinningCore.threadids(; threadpool)
    nt = length(tids_pool)
    cpuids = zeros(Int, nt)
    for (i, threadid) in pairs(tids_pool)
        cpuids[i] = getcpuid(; threadid)
    end
    return cpuids
end

function ispinned(; threadid::Integer = Threads.threadid())
    if isfaking()
        return faking_ispinned(; threadid)
    end
    return sum(getaffinity(; threadid)) == 1
end

# pinning
function setaffinity(mask; threadid::Integer = Threads.threadid())
    set_initial_affinity_mask()
    set_not_first_pin_attempt()
    if isfaking()
        if sum(mask) > 1
            faking_setispinned(false; threadid)
            i = rand(findall(isone, mask))
        else
            faking_setispinned(true; threadid)
            i = findfirst(isone, mask)
        end
        cpuid = faking_ith_cpuid(i)
        faking_setcpuid(cpuid; threadid)
        return
    end
    masksize = uv_cpumask_size()
    masklen = length(mask)
    if masklen > masksize
        throw(
            ArgumentError("Given mask is to big. Expected mask of length <= $(masksize)."),
        )
    elseif masklen < masksize
        append!(mask, zeros(eltype(mask), masksize - masklen))
    end
    c_threadid = threadid - 1
    @static if VERSION > v"1.11-"
        ret = jl_setaffinity(c_threadid, mask, masksize)
        if !iszero(ret)
            throw(ErrorException("Couldn't set the affinity on this system."))
        end
    else
        uv_thread_setaffinity(threadid, mask)
    end
    return
end

function pinthread(cpuid::Integer; threadid::Integer = Threads.threadid())
    mask = emptymask()
    if !(0 ≤ cpuid ≤ length(mask))
        throw(
            ArgumentError(
                "Invalid cpuid. It must hold 0 ≤ cpuid ≤ masksize ($(length(mask)))).",
            ),
        )
    end
    mask[cpuid+1] = 1
    setaffinity(mask; threadid)
    return
end

function pinthreads(
    cpuids::AbstractVector{<:Integer};
    threadpool::Symbol = :default,
    threadids::AbstractVector{<:Integer} = ThreadPinningCore.threadids(; threadpool),
    nthreads = nothing,
    force = true,
)
    if !(force || ThreadPinningCore.is_first_pin_attempt())
        return
    end
    if isnothing(nthreads)
        nthreads = length(threadids)
    end
    # TODO: maybe add `periodic` kwarg for PBC as alternative to strict `min` below.
    limit = min(length(cpuids), nthreads)
    for (i, threadid) in enumerate(@view(threadids[1:limit]))
        pinthread(cpuids[i]; threadid)
    end
    return
end

function unpinthread(; threadid::Integer = Threads.threadid())
    mask = emptymask()
    fill!(mask, one(eltype(mask)))
    setaffinity(mask; threadid)
    return
end

function unpinthreads(; threadpool::Symbol = :default)
    mask = emptymask()
    fill!(mask, one(eltype(mask)))
    for threadid in threadids(; threadpool)
        setaffinity(mask; threadid)
    end
    return
end

function with_pinthreads(
    f::F,
    args...;
    soft = false,
    threadpool::Symbol = :default,
    kwargs...,
) where {F}
    tids = threadids(; threadpool)
    masks_prior = [getaffinity(; threadid = i) for i in tids]
    cpuids_prior = getcpuids()
    pinthreads(args...; threadpool, kwargs...)
    local res
    try
        res = f()
    finally
        soft || pinthreads(cpuids_prior)
        for (i, threadid) in pairs(tids)
            setaffinity(masks_prior[i]; threadid)
        end
    end
    return res
end

# openblas
include("openblas.jl")


end # module
