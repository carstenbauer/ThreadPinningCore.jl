module ThreadPinningCore

include("utils.jl")
include("libcalls.jl")
include("api.jl")
include("internals.jl")

import .Internals: is_first_pin_attempt, get_initial_affinity_mask

@public threadids
@public pinthread, pinthreads, unpinthread, unpinthreads
@public getcpuid, getcpuids, ispinned
@public getaffinity, setaffinity, printaffinity, emptymask, printmask

end
