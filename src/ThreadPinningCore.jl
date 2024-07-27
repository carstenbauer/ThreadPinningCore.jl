module ThreadPinningCore

function cpuidlimit end

include("utils.jl")
include("libcalls.jl")
include("api.jl")
include("internals.jl")

import .Internals: is_first_pin_attempt, get_initial_affinity_mask

@public threadids
@public pinthread, pinthreads, unpinthread, unpinthreads, with_pinthreads
@public getcpuid, getcpuids, ispinned
@public getaffinity, setaffinity, printaffinity, emptymask, printmask
@public openblas_nthreads, openblas_getaffinity, openblas_setaffinity
@public openblas_getcpuid, openblas_getcpuids, openblas_ispinned
@public openblas_printaffinity, openblas_printaffinities
@public openblas_pinthread, openblas_pinthreads, openblas_unpinthread, openblas_unpinthreads

import PrecompileTools
PrecompileTools.@compile_workload begin
    redirect_stdout(Base.DevNull()) do
        threadids()
        @static if Sys.islinux()
            getcpuid()
            getcpuids()
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
