module LibCalls

using StableTasks: @fetchfrom

# libc
sched_getcpu() = @ccall sched_getcpu()::Cint


# libjulia
function jl_getaffinity(tid, mask, cpumasksize)
    ccall(:jl_getaffinity, Int32, (Int16, Ptr{Cchar}, Int32), tid, mask, cpumasksize)
end

function jl_setaffinity(tid, mask, cpumasksize)
    ccall(:jl_setaffinity, Int32, (Int16, Ptr{Cchar}, Int32), tid, mask, cpumasksize)
end


# libuv
const uv_thread_t = Culong

uv_cpumask_size() = @ccall uv_cpumask_size()::Cint
uv_thread_self() = @ccall uv_thread_self()::uv_thread_t

function uv_thread_getaffinity(self_ref, cpumask, masksize = uv_cpumask_size())
    @ccall uv_thread_getaffinity(
        self_ref::Ptr{uv_thread_t},
        cpumask::Ptr{Cchar},
        masksize::Cssize_t,
    )::Cint
end
function uv_thread_getaffinity()
    masksize = uv_cpumask_size()
    if masksize < 0
        throw(ErrorException("Libuv returned an invalid mask size. Unsupported OS?"))
    end
    mask = zeros(Cchar, masksize)
    ret = uv_thread_getaffinity(Ref(uv_thread_self()), mask, masksize)
    if ret != 0
        throw(ErrorException("uv_thread_getaffinity returned a non-zero error code: $ret"))
    end
    return mask
end
function uv_thread_getaffinity(tid::Integer)
    mask = @fetchfrom tid uv_thread_getaffinity()
    return mask
end

function uv_thread_setaffinity(self_ref, cpumask, oldmask, masksize = uv_cpumask_size())
    @ccall uv_thread_setaffinity(
        self_ref::Ptr{uv_thread_t},
        cpumask::Ptr{Cchar},
        oldmask::Ptr{Cchar},
        masksize::Csize_t,
    )::Cint
end
function uv_thread_setaffinity(mask::Vector{<:Integer})
    ret = uv_thread_setaffinity(Ref(uv_thread_self()), mask, C_NULL)
    if ret != 0
        throw(ErrorException("uv_thread_setaffinity returned a non-zero error code: $ret"))
    end
    return
end
function uv_thread_setaffinity(tid::Integer, mask::Vector{<:Integer})
    @fetchfrom tid uv_thread_setaffinity(mask)
    return
end


# pthread
include("libpthread.jl")


# openblas
function openblas_nthreads()
    Int(@ccall "libopenblas64_.so".openblas_get_num_threads64_()::Cint)
end

"Sets the thread affinity for the `i`-th OpenBLAS thread. Thread index `i` starts at zero."
function openblas_setaffinity(i, cpusetsize, cpu_set::Ref{Ccpu_set_t})
    @ccall "libopenblas64_.so".openblas_setaffinity(
        i::Cint,
        cpusetsize::Csize_t,
        cpu_set::Ptr{Ccpu_set_t},
    )::Cint
end

# Get thread affinity for OpenBLAS threads. `threadid` starts at 0
function openblas_getaffinity(threadid, cpusetsize, cpu_set::Ref{Ccpu_set_t})
    @ccall "libopenblas64_.so".openblas_getaffinity(
        threadid::Cint,
        cpusetsize::Csize_t,
        cpu_set::Ptr{Ccpu_set_t},
    )::Cint
end


end # module
