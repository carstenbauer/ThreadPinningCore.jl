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
    unpinthreads

using StableTasks: @fetchfrom

using ..LibCalls:
    jl_setaffinity,
    jl_getaffinity,
    uv_thread_getaffinity,
    uv_thread_setaffinity,
    uv_cpumask_size,
    sched_getcpu

# global constants
"The affinity mask (of the main Julia thread) before any pinning has happened."
const INITIAL_AFFINITY_MASK = Ref{Union{Nothing,Vector{Cchar}}}(nothing)
"Indicates whether we have not called a pinning function (-> `setaffinity`) before."
const FIRST_PIN = Ref{Bool}(true)

# FIRST_PIN handlers
is_first_pin_attempt() = FIRST_PIN[]
function set_not_first_pin_attempt()
    FIRST_PIN[] = false
    return
end
function forget_pin_attempts()
    FIRST_PIN[] = true
    return
end

# INITIAL_AFFINITY_MASK handlers
get_initial_affinity_mask() = INITIAL_AFFINITY_MASK[]
function set_initial_affinity_mask(mask = getaffinity(); force = false)
    if force || is_first_pin_attempt()
        INITIAL_AFFINITY_MASK[] = mask
    end
    return
end

function emptymask()
    masksize = uv_cpumask_size()
    mask = zeros(Cchar, masksize)
    return mask
end

function getaffinity(;
    threadid::Integer = Threads.threadid(),
    cutoff::Union{Integer,Nothing} = Sys.CPU_THREADS,
)
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

function setaffinity(mask; threadid::Integer = Threads.threadid())
    set_initial_affinity_mask()
    set_not_first_pin_attempt()
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

function pinthreads(
    cpuids::AbstractVector{<:Integer};
    threadids::AbstractVector{<:Integer} = ThreadPinningCore.threadids(),
)
    limit = min(length(cpuids), length(threadids))
    for (i, threadid) in enumerate(@view(threadids[1:limit]))
        c = cpuids[i]
        pinthread(c; threadid)
    end
    return
end

ispinned(; threadid::Integer = Threads.threadid()) = sum(getaffinity(; threadid)) == 1

function getcpuid(; threadid::Union{Integer,Nothing} = nothing)
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

printmask(mask; kwargs...) = printmask(stdout, mask; kwargs...)
function printmask(io, mask; cutoff = Sys.CPU_THREADS)
    for i = 1:cutoff
        print(io, mask[i])
    end
    print("\n")
end

printaffinity(; threadid::Integer = Threads.threadid()) = printmask(getaffinity(; threadid))

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

end # module
