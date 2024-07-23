module ThreadPinningCore

include("utils.jl")
include("libcalls.jl")
include("api.jl")
include("internals.jl")

@public threadids
export pinthread,
    pinthreads, ispinned, getaffinity, getcpuid, getcpuids, printmask, printaffinity

end
