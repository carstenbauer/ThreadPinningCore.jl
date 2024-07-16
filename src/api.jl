module API

using ..LibCalls: jl_getaffinity, cpumasksize
using Base.Threads: threadid

function getaffinity(tid = threadid())
    c_tid = tid-1
    # TODO: make PR to move mask creation to Julia C side
    masksize = cpumasksize()
    mask = zeros(Cchar, masksize);
    # @assert cpumasksize > 0
    ret = jl_getaffinity(c_tid, mask, masksize)
    if !iszero(ret)
        throw(ErrorException("Couldn't query the affinity on this system."))
    end
    return ret
end

end # module
