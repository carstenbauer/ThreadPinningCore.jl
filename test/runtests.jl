using ThreadPinningCore
using Test
using Base.Threads: threadid, @threads, nthreads
using LinearAlgebra: BLAS
BLAS.set_num_threads(4)

const TPC = ThreadPinningCore

if nthreads() == 1
    @warn("Running test suite with a single thread.")
end

@static if Sys.islinux()
    @testset "ThreadPinningCore.jl" begin
        @test TPC.ispinned() == false
        @test TPC.getaffinity() isa Vector{<:Integer}
        mask = TPC.getaffinity()
        @test length(mask) >= Sys.CPU_THREADS
        @test sum(mask) > 0
        @test isnothing(TPC.printmask(mask))
        @test isnothing(TPC.printaffinity())
        @test TPC.threadids() isa UnitRange{Int}
        @test TPC.getcpuid() isa Integer
        @test TPC.getcpuid() >= 0
        @test TPC.getcpuid(; threadid = 1) >= 0
        @test TPC.getcpuids() isa Vector{Int}
        @test TPC.Internals.is_first_pin_attempt()
        @test isnothing(TPC.pinthread(0))
        @test TPC.ispinned()
        @test !TPC.Internals.is_first_pin_attempt()
        @test !isnothing(TPC.Internals.get_initial_affinity_mask())
        @test isnothing(TPC.pinthreads([0]))
        @test isnothing(TPC.unpinthread())
        @test !TPC.ispinned()
        @test isnothing(TPC.unpinthreads())
        mask = TPC.emptymask()
        mask[1] = 1
        @test isnothing(TPC.setaffinity(mask))

        tid = first(TPC.threadids(; threadpool = :default))
        TPC.pinthread(1; threadid = tid)
        TPC.with_pinthreads([0]; threadpool = :default) do
            @test TPC.getcpuid(; threadid = tid) == 0
        end
        @test TPC.getcpuid(; threadid = tid) == 1
        TPC.getcpuids()

        @testset "OpenBLAS" begin
            # not pinned yet
            @test_throws ErrorException TPC.openblas_getcpuid(; threadid = 1)
            @test_throws ErrorException TPC.openblas_getcpuids()
            @test TPC.openblas_nthreads() == BLAS.get_num_threads()
            c = TPC.getcpuid()
            @test isnothing(TPC.openblas_pinthread(c; threadid = 1))
            @test TPC.openblas_getcpuid(; threadid = 1) == c
            @test TPC.openblas_ispinned(; threadid = 1)
            TPC.openblas_unpinthread(; threadid = 1)
            @test !TPC.openblas_ispinned(; threadid = 1)
            TPC.openblas_unpinthreads()
            @test isnothing(TPC.openblas_pinthreads(fill(c, TPC.openblas_nthreads())))
            @test all(==(c), TPC.openblas_getcpuids())
            @test isnothing(TPC.openblas_printaffinity(; threadid = 1))
            @test isnothing(TPC.openblas_printaffinities())
        end

        @testset "Fake mode" begin
            # prelude
            fake_cpuids = [0, 2, 3, 14, 5, 44, 32] # chosen with gaps and unsorted
            fake_cpuids_shuffled = [32, 44, 0, 3, 14, 2, 5]
            nt = length(TPC.threadids())
            first_tid = first(TPC.threadids())

            # setup
            @test !TPC.Internals.isfaking()
            @test isnothing(TPC.Internals.enable_faking(fake_cpuids)) # random fake cpuids
            @test TPC.Internals.isfaking()
            for threadid in TPC.threadids(; threadpool = :all)
                @test !TPC.Internals.ispinned()
            end

            # regular usage
            TPC.pinthreads(fake_cpuids_shuffled)
            @test TPC.getcpuids() == fake_cpuids_shuffled[1:nt]
            @test TPC.getcpuid(; threadid = first_tid) == fake_cpuids_shuffled[1]
            @show findall(isone, TPC.getaffinity(; threadid = first_tid)) == [33]
            mask = TPC.emptymask()
            @test length(mask) == maximum(fake_cpuids) + 1
            mask[3+1] = 1 # cpuid = 3
            TPC.setaffinity(mask; threadid = first_tid)
            @test TPC.getcpuid(; threadid = first_tid) == 3
            @test TPC.ispinned(; threadid = first_tid)
            @test isnothing(TPC.unpinthreads())
            @test !TPC.ispinned(; threadid = first_tid)

            # regular usage (OpenBLAS)
            @test_throws ErrorException TPC.openblas_getcpuid(; threadid = 1) # not pinned yet
            @test_throws ErrorException TPC.openblas_getcpuids()

            c = maximum(fake_cpuids)
            @test isnothing(TPC.openblas_pinthread(c; threadid = 1))
            @test TPC.openblas_getcpuid(; threadid = 1) == c

            @test isnothing(TPC.openblas_pinthreads(fill(c, TPC.openblas_nthreads())))
            @test all(==(c), TPC.openblas_getcpuids())

            # restore
            TPC.Internals.disable_faking()
            @test !TPC.Internals.isfaking()
        end
    end
end
