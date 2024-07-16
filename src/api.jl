module API

using ..LibCalls: jl_setaffinity, jl_getaffinity, uv_cpumask_size, sched_getcpu
using Base.Threads: threadid

"Get the thread affinity of a thread."
function getaffinity(; tid::Integer = threadid())
    c_tid = tid - 1
    masksize = uv_cpumask_size()
    mask = zeros(Cchar, masksize)
    ret = jl_getaffinity(c_tid, mask, masksize)
    if !iszero(ret)
        throw(ErrorException("Couldn't query the affinity on this system."))
    end
    return mask
end

"Pin a thread to the given CPU thread."
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
    ret = jl_setaffinity(c_tid, mask, masksize)
    if !iszero(ret)
        throw(ErrorException("Couldn't set the affinity on this system."))
    end
    return nothing
end

ispinned(; tid = threadid()) = sum(getaffinity(; tid)) == 1

getcpuid() = sched_getcpu()

ncputhreads() = Sys.CPU_THREADS

printmask(mask; kwargs...) = printmask(stdout, mask; kwargs...)
function printmask(io, mask; cutoff = ncputhreads())
    for i in 1:cutoff
        print(io, mask[i])
    end
    print("\n")
end

printaffinity(; tid=threadid()) = printmask(getaffinity(; tid))

end # module
