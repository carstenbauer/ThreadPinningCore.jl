module LibCalls

# libjulia
function jl_getaffinity(tid, mask, cpumasksize)
    ccall(:jl_getaffinity, Int32, (Int16, Ptr{Cchar}, Int32), tid, mask, cpumasksize)
end

function jl_setaffinity(tid, mask, cpumasksize)
    ccall(:jl_setaffinity, Int32, (Int16, Ptr{Cchar}, Int32), tid, mask, cpumasksize)
end


# libuv
cpumasksize() = @ccall uv_cpumask_size()::Cint


# libc
getcpuid() = @ccall sched_getcpu()::Cint

end # module
