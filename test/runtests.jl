using ThreadPinningCore
using Test
using Base.Threads: threadid, @threads, nthreads

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

        mask = TPC.emptymask()
        mask[1] = 1
        @test isnothing(TPC.setaffinity(mask))

        @test TPC.threadids() isa UnitRange{Int}

        # TODO: Test kwargs
    end
end
