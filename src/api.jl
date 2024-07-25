"""
Set the affinity of the calling Julia thread to the given CPU-threads.
"""
function setaffinity end

"""
Get an empty mask (to be used as input for [`setaffinity`](@ref)).
"""
function emptymask end

"""
Get the thread affinity of a thread. Returns the affinity mask as a vector of zeros and
ones.
By default, the mask is cut off at `Sys.CPU_THREADS`. This can be tuned via the
`cutoff` keyword argument (`nothing` means no cutoff).
"""
function getaffinity end

"Pin a thread to the given CPU thread."
function pinthread end

"Pin multiple threads to the given list of CPU threads."
function pinthreads end

"Check if a thread is pinned to a single CPU thread."
function ispinned end

"Get the id of the CPU thread a thread is currently running on."
function getcpuid end

"Get the ids of the CPU threads on which the Julia threads are currently running on."
function getcpuids end

"Print a mask in a compact way."
function printmask end

"Print the affinity of the calling thread."
function printaffinity end

"Get the IDs (`threadid()`) of the Julia threads, optionally of a given threadpool."
function threadids end

"""
Unpins the given Julia thread by setting the affinity mask to all unity.
Afterwards, the OS is free to move the Julia thread from one CPU thread to another.
"""
function unpinthread end

"""
Unpins all Julia threads by setting the affinity mask of all threads to all unity.
Afterwards, the OS is free to move any Julia thread from one CPU thread to another.
"""
function unpinthreads end
