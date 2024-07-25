module ThreadPinningCore

include("utils.jl")
include("libcalls.jl")
include("api.jl")
include("internals.jl")

import .Internals: is_first_pin_attempt, get_initial_affinity_mask

@public threadids
@public pinthread, pinthreads, unpinthread, unpinthreads, with_pinthreads
@public getcpuid, getcpuids, ispinned
@public getaffinity, setaffinity, printaffinity, emptymask, printmask

import PrecompileTools
PrecompileTools.@compile_workload begin
    redirect_stdout(Base.DevNull()) do
        threadids()
        getcpuid()
        getcpuids()
        @static if Sys.islinux()
            pinthread(0)
            pinthreads([0])
            ispinned()
            unpinthread()
            unpinthreads()
            getaffinity()
            with_pinthreads([0]) do
                nothing
            end
            printaffinity()
        end
    end
    ThreadPinningCore.Internals.globals_reset()
end

end
