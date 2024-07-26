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

        TPC.pinthread(1)
        TPC.with_pinthreads(0:0) do
            @test TPC.getcpuid() == 0
        end
        @test TPC.getcpuid() == 1

        TPC.getcpuids()

        @test TPC.threadids() isa UnitRange{Int}

        # TODO: Test kwargs
        # TODO: test faking mode

        @testset "OpenBLAS" begin
            # not pinned yet
            @test_throws ErrorException TPC.openblas_getcpuid(; threadid = 1)
            @test_throws ErrorException TPC.openblas_getcpuids()
            @test TPC.openblas_nthreads() == BLAS.get_num_threads()

            c = TPC.getcpuid()
            @test isnothing(TPC.openblas_pinthread(c; threadid=1))
            @test TPC.openblas_getcpuid(; threadid=1) == c

            @test isnothing(TPC.openblas_pinthreads(fill(c, TPC.openblas_nthreads())))
            @test all(==(c), TPC.openblas_getcpuids())

            @test isnothing(TPC.openblas_printaffinity(; threadid=1))
            @test isnothing(TPC.openblas_printaffinities())
        end
    end
end
