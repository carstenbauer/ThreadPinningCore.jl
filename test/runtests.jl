using ThreadPinningCore
using Test
using Base.Threads: threadid, @threads, nthreads
using LinearAlgebra: BLAS
BLAS.set_num_threads(4)

if nthreads() == 1
    @warn("Running test suite with a single thread.")
end

@static if Sys.islinux()
    @testset "ThreadPinningCore.jl" begin
        @test ispinned() == false
        @test getaffinity() isa Vector{<:Integer}
        mask = getaffinity()
        @test length(mask) >= Sys.CPU_THREADS
        @test sum(mask) > 0
        @test isnothing(printmask(mask))
        @test isnothing(printaffinity())
        @test threadids() isa UnitRange{Int}
        @test getcpuid() isa Integer
        @test getcpuid() >= 0
        @test getcpuid(; threadid = 1) >= 0
        @test getcpuids() isa Vector{Int}
        @test ThreadPinningCore.Internals.is_first_pin_attempt()
        @test isnothing(pinthread(0))
        @test ispinned()
        @test !ThreadPinningCore.Internals.is_first_pin_attempt()
        @test !isnothing(ThreadPinningCore.Internals.get_initial_affinity_mask())
        @test isnothing(pinthreads([0]))
        @test isnothing(unpinthread())
        @test !ispinned()
        @test isnothing(unpinthreads())
        mask = emptymask()
        mask[1] = 1
        @test isnothing(setaffinity(mask))

        tid = first(threadids(; threadpool = :default))
        pinthread(1; threadid = tid)
        with_pinthreads([0]; threadpool = :default) do
            @test getcpuid(; threadid = tid) == 0
        end
        @test getcpuid(; threadid = tid) == 1
        getcpuids()

        @testset "OpenBLAS" begin
            # not pinned yet
            @test_throws ErrorException openblas_getcpuid(; threadid = 1)
            @test_throws ErrorException openblas_getcpuids()
            @test openblas_nthreads() == BLAS.get_num_threads()
            c = getcpuid()
            @test isnothing(openblas_pinthread(c; threadid = 1))
            @test openblas_getcpuid(; threadid = 1) == c
            @test openblas_ispinned(; threadid = 1)
            openblas_unpinthread(; threadid = 1)
            @test !openblas_ispinned(; threadid = 1)
            openblas_unpinthreads()
            @test isnothing(openblas_pinthreads(fill(c, openblas_nthreads())))
            @test all(==(c), openblas_getcpuids())
            @test isnothing(openblas_printaffinity(; threadid = 1))
            @test isnothing(openblas_printaffinities())
        end

        @testset "Fake mode" begin
            # prelude
            fake_cpuids = [0, 2, 3, 14, 5, 44, 32] # chosen with gaps and unsorted
            fake_cpuids_shuffled = [32, 44, 0, 3, 14, 2, 5]
            nt = length(threadids())
            first_tid = first(threadids())

            # setup
            @test !ThreadPinningCore.Internals.isfaking()
            @test isnothing(ThreadPinningCore.Internals.enable_faking(fake_cpuids)) # random fake cpuids
            @test ThreadPinningCore.Internals.isfaking()
            for threadid in threadids(; threadpool = :all)
                @test !ThreadPinningCore.Internals.ispinned()
            end

            # regular usage
            pinthreads(fake_cpuids_shuffled)
            @test getcpuids() == fake_cpuids_shuffled[1:nt]
            @test getcpuid(; threadid = first_tid) == fake_cpuids_shuffled[1]
            @show findall(isone, getaffinity(; threadid = first_tid)) == [33]
            mask = emptymask()
            @test length(mask) == maximum(fake_cpuids) + 1
            mask[3+1] = 1 # cpuid = 3
            setaffinity(mask; threadid = first_tid)
            @test getcpuid(; threadid = first_tid) == 3
            @test ispinned(; threadid = first_tid)
            @test isnothing(unpinthreads())
            @test !ispinned(; threadid = first_tid)

            # regular usage (OpenBLAS)
            @test_throws ErrorException openblas_getcpuid(; threadid = 1) # not pinned yet
            @test_throws ErrorException openblas_getcpuids()

            c = maximum(fake_cpuids)
            @test isnothing(openblas_pinthread(c; threadid = 1))
            @test openblas_getcpuid(; threadid = 1) == c

            @test isnothing(openblas_pinthreads(fill(c, openblas_nthreads())))
            @test all(==(c), openblas_getcpuids())

            # restore
            ThreadPinningCore.Internals.disable_faking()
            @test !ThreadPinningCore.Internals.isfaking()
        end
    end
end
