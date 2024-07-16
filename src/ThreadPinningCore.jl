module ThreadPinningCore

include("libcalls.jl")
include("api.jl")

using .API: pinthread, getaffinity, ispinned, getcpuid, ncputhreads, printmask, printaffinity

export pinthread, getaffinity, ispinned, getcpuid, ncputhreads, printmask, printaffinity

end
