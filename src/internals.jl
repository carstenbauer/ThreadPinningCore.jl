module Internals

import ThreadPinningCore:
    ThreadPinningCore,
    getaffinity,
    pinthread,
    ispinned,
    getcpuid,
    printmask,
    printaffinity,
    threadids,
    pinthreads

using StableTasks: @fetchfrom

using ..LibCalls:
    jl_setaffinity,
    jl_getaffinity,
    uv_thread_getaffinity,
    uv_thread_setaffinity,
    uv_cpumask_size,
    sched_getcpu

function getaffinity(; threadid::Integer = Threads.threadid())
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
    return mask
end

function pinthread(cpuid::Integer; threadid::Integer = Threads.threadid())
    c_threadid = threadid - 1
    masksize = uv_cpumask_size()
    if !(0 ≤ cpuid ≤ masksize)
        throw(
            ArgumentError("Invalid cpuid. It must hold 0 ≤ cpuid ≤ masksize ($masksize)."),
        )
    end
    mask = zeros(Cchar, masksize)
    mask[cpuid+1] = 1
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

function threadids(; threadpool = :default)
    if threadpool == :default
        return Threads.nthreads(:interactive) .+ (1:Threads.nthreads(:default))
    elseif threadpool == :interactive
        return 1:Threads.nthreads(:interactive)
    elseif threadpool == :all
        return 1:(Threads.nthreads(:interactive)+Threads.nthreads(:default))
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

printmask(mask; kwargs...) = printmask(stdout, mask; kwargs...)
function printmask(io, mask; cutoff = Sys.CPU_THREADS)
    for i = 1:cutoff
        print(io, mask[i])
    end
    print("\n")
end

printaffinity(; threadid::Integer = Threads.threadid()) = printmask(getaffinity(; threadid))

end # module
