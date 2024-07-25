module ThreadPinningCore

include("utils.jl")
include("libcalls.jl")
include("api.jl")
include("internals.jl")

@public threadids
@public pinthread, pinthreads
@public getcpuid, getcpuids, ispinned
@public getaffinity, setaffinity, printaffinity, emptymask, printmask

end
