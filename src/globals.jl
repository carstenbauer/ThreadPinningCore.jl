# global constants
"The affinity mask (of the main Julia thread) before any pinning has happened."
const INITIAL_AFFINITY_MASK = Ref{Union{Nothing,Vector{Cchar}}}(nothing)
"Indicates whether we have not called a pinning function (-> `setaffinity`) before."
const FIRST_PIN = Ref{Bool}(true)

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
