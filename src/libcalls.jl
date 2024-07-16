module LibCalls

using StableTasks: @spawnat

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
    mask = zeros(Cchar, masksize)
    ret = uv_thread_getaffinity(Ref(uv_thread_self()), mask, masksize)
    if ret != 0
        throw(ErrorException("uv_thread_getaffinity returned a non-zero error code: $ret"))
    end
    return mask
end
function uv_thread_getaffinity(tid::Integer)
    mask = fetch(@spawnat tid uv_thread_getaffinity())
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
    fetch(@spawnat tid uv_thread_setaffinity(mask))
    return
end


# libc
sched_getcpu() = @ccall sched_getcpu()::Cint

end # module
