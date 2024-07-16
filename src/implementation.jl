module Implementation

import ThreadPinningCore:
    getaffinity, pinthread, ispinned, getcpuid, printmask, printaffinity

using ..LibCalls:
    jl_setaffinity,
    jl_getaffinity,
    uv_thread_getaffinity,
    uv_thread_setaffinity,
    uv_cpumask_size,
    sched_getcpu
using Base.Threads: threadid

function getaffinity(; tid::Integer = threadid())
    @static if VERSION > v"1.11-"
        c_tid = tid - 1
        masksize = uv_cpumask_size()
        mask = zeros(Cchar, masksize)
        ret = jl_getaffinity(c_tid, mask, masksize)
        if !iszero(ret)
            throw(ErrorException("Couldn't query the affinity on this system."))
        end
    else
        mask = uv_thread_getaffinity(tid)
    end
    return mask
end

function pinthread(cpuid::Integer; tid::Integer = threadid())
    c_tid = tid - 1
    masksize = uv_cpumask_size()
    if !(0 ≤ cpuid ≤ masksize)
        throw(
            ArgumentError("Invalid cpuid. It must hold 0 ≤ cpuid ≤ masksize ($masksize)."),
        )
    end
    mask = zeros(Cchar, masksize)
    mask[cpuid+1] = 1
    @static if VERSION > v"1.11-"
        ret = jl_setaffinity(c_tid, mask, masksize)
        if !iszero(ret)
            throw(ErrorException("Couldn't set the affinity on this system."))
        end
    else
        uv_thread_setaffinity(mask)
    end
    return nothing
end

ispinned(; tid = threadid()) = sum(getaffinity(; tid)) == 1

getcpuid() = sched_getcpu()

printmask(mask; kwargs...) = printmask(stdout, mask; kwargs...)
function printmask(io, mask; cutoff = Sys.CPU_THREADS)
    for i = 1:cutoff
        print(io, mask[i])
    end
    print("\n")
end

printaffinity(; tid = threadid()) = printmask(getaffinity(; tid))

end # module
