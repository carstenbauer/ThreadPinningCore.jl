using ThreadPinningCore
using Test
using Base.Threads: threadid, @threads, nthreads

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
        @test getcpuid() isa Integer
        @test getcpuid() >= 0

        @test isnothing(pinthread(0))
        @test ispinned()

        @test isnothing(pinthreads([0]))

        @test ThreadPinningCore.threadids() isa UnitRange{Int}

        # TODO: Test kwargs
    end
end
