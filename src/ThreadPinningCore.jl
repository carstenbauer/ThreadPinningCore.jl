module ThreadPinningCore

include("libcalls.jl")
include("api.jl")
include("implementation.jl")

export pinthread, getaffinity, ispinned, getcpuid, printmask, printaffinity, @spawnat

end
