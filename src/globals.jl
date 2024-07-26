# global constants
"The affinity mask (of the main Julia thread) before any pinning has happened."
const INITIAL_AFFINITY_MASK = Ref{Union{Nothing,Vector{Cchar}}}(nothing)
"Indicates whether we have not called a pinning function (-> `setaffinity`) before."
const FIRST_PIN = Ref{Bool}(true)
const FAKING = Ref{Bool}(false)
const FAKE_THREADS_CPUIDS = Ref{Union{Nothing,Dict{Int,Int}}}(nothing)
const FAKE_ALLOWED_CPUIDS = Ref{Union{Nothing,Vector{Int}}}(nothing)
const FAKE_THREADS_ISPINNED = Ref{Union{Nothing,Dict{Int,Bool}}}(nothing)

function globals_reset()
    INITIAL_AFFINITY_MASK[] = nothing
    FIRST_PIN[] = true
    FAKING[] = false
    FAKE_THREADS_CPUIDS[] = nothing
    FAKE_ALLOWED_CPUIDS[] = nothing
    FAKE_THREADS_ISPINNED[] = nothing
    return
end

# FIRST_PIN handlers
is_first_pin_attempt() = FIRST_PIN[]
function set_not_first_pin_attempt()
    FIRST_PIN[] = false
    return
end
function forget_pin_attempts()
    FIRST_PIN[] = true
    return
end

# INITIAL_AFFINITY_MASK handlers
function get_initial_affinity_mask()
    if isnothing(INITIAL_AFFINITY_MASK[])
        set_initial_affinity_mask()
    end
    return INITIAL_AFFINITY_MASK[]
end
function set_initial_affinity_mask(mask = getaffinity(); force = false)
    if force || is_first_pin_attempt()
        INITIAL_AFFINITY_MASK[] = mask
    end
    return
end

# FAKING handlers
isfaking() = FAKING[]
function enable_faking(allowed_cpuids::AbstractVector{<:Integer})
    FAKE_ALLOWED_CPUIDS[] = sort(allowed_cpuids)
    FAKE_THREADS_ISPINNED[] = Dict{Int,Bool}()
    FAKE_THREADS_CPUIDS[] = Dict{Int,Int}()
    for tid in threadids(; threadpool = :all)
        FAKE_THREADS_CPUIDS[][tid] = rand(FAKE_ALLOWED_CPUIDS[])
        FAKE_THREADS_ISPINNED[][tid] = false
    end
    FAKING[] = true
    return
end
function disable_faking()
    FAKING[] = false
    FAKE_THREADS_CPUIDS[] = nothing
    FAKE_THREADS_ISPINNED[] = nothing
    FAKE_ALLOWED_CPUIDS[] = nothing
    return
end
faking_allowed_cpuids() = FAKE_ALLOWED_CPUIDS[]
# faking_get_threads_cpuids() = FAKE_THREADS_CPUIDS[]
faking_getcpuid(; threadid::Integer = Threads.threadid()) = FAKE_THREADS_CPUIDS[][threadid]
function faking_setcpuid(cpuid::Integer; threadid::Integer = Threads.threadid())
    FAKE_THREADS_CPUIDS[][threadid] = cpuid
    return
end
faking_ith_cpuid(i::Integer) = FAKE_ALLOWED_CPUIDS[][i]
faking_ispinned(; threadid::Integer = Threads.threadid()) =
    FAKE_THREADS_ISPINNED[][threadid]
function faking_setispinned(val::Bool; threadid::Integer = Threads.threadid())
    FAKE_THREADS_ISPINNED[][threadid] = val
    return
end
