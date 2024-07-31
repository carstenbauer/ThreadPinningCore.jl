module ThreadPinningCore

function cpuidlimit end

include("utils.jl")
include("libcalls.jl")
include("api.jl")
include("internals.jl")

import .Internals: is_first_pin_attempt, get_initial_affinity_mask

export threadids
export pinthread, pinthreads, unpinthread, unpinthreads, with_pinthreads
export getcpuid, getcpuids, ispinned
export getaffinity, setaffinity, printaffinity, emptymask, printmask
export openblas_nthreads, openblas_getaffinity, openblas_setaffinity
export openblas_getcpuid, openblas_getcpuids, openblas_ispinned
export openblas_printaffinity, openblas_printaffinities
export openblas_pinthread, openblas_pinthreads, openblas_unpinthread, openblas_unpinthreads

import PrecompileTools
PrecompileTools.@compile_workload begin
    redirect_stdout(Base.DevNull()) do
        threadids()
        @static if Sys.islinux()
            getcpuid()
            getcpuids()
            getaffinity()
            printaffinity()
            ispinned()
            try
                pinthread(0)
                pinthreads([0])
                unpinthread()
                unpinthreads()
                with_pinthreads([0]) do
                    nothing
                end
            catch err
            end
        end
    end
    ThreadPinningCore.Internals.globals_reset()
end

end
