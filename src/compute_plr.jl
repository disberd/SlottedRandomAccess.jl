# This computes the PLR result for a given load using multiple threads
function compute_plr_result(params::PLR_SimulationParameters, load)
    (; scheme, poisson, coderate, M, max_simulated_frames, nslots, max_errored_frames, power_dist, power_strategy) = params
    coding_gain = 1 / (coderate * log2(M))
    mean_users = nslots * load * coding_gain
    ## These 4 variables will be used to track simualted frames/packets and errors **
    errored_frames = 0
    total_decoded = 0
    total_sent = 0
    simulated_frames = 0
    ## End of tracking variables
    l = ReentrantLock() # We use this to avoid race conditions in modifying the number of frames/packets
    Threads.@threads for idxs in chunks(1:max_simulated_frames; size=50)
        inner_errored = 0
        inner_simulated = 0
        inner_sent = 0
        inner_decoded = 0
        for _ in idxs
            # Compute the effective number of users for this frame
            nusers = poisson ? rand(Poisson(mean_users)) : round(Int, mean_users)
            ndecoded = @no_escape begin
                # Initialize the vector of users
                users = @alloc(UserRealization{max_replicas(scheme),typeof(scheme),typeof(power_dist)}, nusers)
                # Initialize the matrix of power allocations
                power_matrix = @alloc(Float64, nusers, nslots)
                # Make sure that power_matrix has all zeros
                fill!(power_matrix, zero(eltype(power_matrix)))
                # Instantiate the users for this frame
                for u in eachindex(users)
                    users[u] = UserRealization(scheme, nslots; power_dist, power_strategy)
                end
                # Populate the power_matrix with the power of the users replicas
                allocate_users!(power_matrix, users)
                ndecoded = process_frame!(power_matrix, users; params)
            end
            inner_decoded += ndecoded
            inner_sent += nusers
            inner_errored += ndecoded < nusers
            inner_simulated += 1
        end
        lock(l) do # Lock to prevent race conditions
            total_decoded += inner_decoded
            total_sent += inner_sent
            errored_frames += inner_errored
            simulated_frames += inner_simulated
        end
        # Break if we reached the max number of errored frames
        errored_frames >= max_errored_frames && break
    end
    plr_result = PLR_Result(; simulated_frames, total_decoded, errored_frames, total_sent)
    # Compute the PLR for this load point
    return plr_result
end

"""
	process_frame!(power_matrix, users; params::PLR_SimulationParameters)
Perform the SIC decoding for a given matrix `power_matrix` containing the
power/slots allocation of the packets of the users in `users` and returns the
number of decoded users at the end of the SIC process.
"""
function process_frame!(power_matrix, users; params::PLR_SimulationParameters)
    @assert length(users) === size(power_matrix, 1) "Mismatch in matrix rows and number of users"
    nusers, nslots = size(power_matrix)
    @no_escape begin
        decoded = @alloc(Bool, nusers) # This will track which user is decoded
        cancelled = @alloc(Bool, nusers) # This will track which user is cancelled
        slots_powers = @alloc(eltype(power_matrix), nslots)
        (; noise_variance) = params
        interference_changed = @alloc(Bool, nslots) # This will hold a flag per slot specifying whether the intereference in the slot changed in the last iteration
        # We initialize the arrays used for the computation
        fill!(decoded, false)
        fill!(cancelled, false)
        fill!(interference_changed, true)
        # Track the total power per slot, including noise power
        for s in eachindex(slots_powers)
            @views slots_powers[s] = sum(power_matrix[:, s]) + noise_variance
        end
        # We perform the iterations
        _decoding_iterations!(slots_powers, decoded, cancelled, interference_changed; params, users)
        sum(decoded)
    end
end

# Block actualy performing the decoding iterations for a single frame
function _decoding_iterations!(slots_powers, decoded, cancelled, interference_changed; params, users)
    (; coderate, M, plr_func, SIC_iterations) = params
    coding_gain = 1 / (coderate * log2(M))
    for iter in 1:SIC_iterations
        all(decoded) && break # Stop the simulation if all users are decoded
        for u in eachindex(users)
            decoded[u] && continue # Skip user if already decoded
            for (; slot, power) in users[u].slots_powers
                interference_changed[slot] || continue
                snir_this = power / (slots_powers[slot] - power)
                ebno = snir_this * coding_gain
                # Use a coin flip to check if a packet is decoded, based on the PLR for the experienced ebno
                this_decoded = rand() >= plr_func(ebno)
                if this_decoded
                    decoded[u] = true
                    break # We skip the rest of the packtes for this user once the first is decoded
                end
            end
        end
        # We reset the interference changed status
        fill!(interference_changed, false)
        # After having iterated all decoding, we iterate again to cancel decoded users
        for u in eachindex(users)
            decoded[u] && !cancelled[u] || continue # Skip if already cancelled or not yet decoded
            for (; slot, power) in users[u].slots_powers
                interference_changed[slot] = true # We signal that inteference in the slot changed in the last iteration
                slots_powers[slot] -= power # Remove the decoded packet power from the slot
            end
            cancelled[u] = true
        end
    end
    return nothing
end

"""
    plrs = extract_plr(sim::PLR_Simulation)
    plr = extract_plr(p::Union{PLR_Simulation_Point,PLR_Result})

Extract the PLR value (as a number between 0 and 1) from either a `PLR_Simulation` or a single `PLR_Simulation_Point` or `PLR_Result`.

In the first case, the function will return a vector with an element for each load point in the `PLR_Simulation` object.
"""
function extract_plr end
# Compute the actual PLR value (between 0 and 1) from the PLR_Result structure
function extract_plr(r::PLR_Result; warn=true)
    is_valid_result(r) || !warn || @warn(
    #! format: off
"The provided PLR result does not seem to correspond to an actual simulation, as the number of simulated frames is 0."
    #! format: off
    )
    plr = 1 - r.total_decoded / r.total_sent
    return plr
end
function extract_plr(s::PLR_Simulation_Point; warn = true)
    (;load, plr) = s
    is_valid_result(s) || !warn || @warn(
    #! format: off
"The load point $load does not seem to have been simulated yet.
To compute the PLR, call `extract_plr!(s::PLR_Simulation)` first."
    #! format: off
    )
    extract_plr(plr; warn=false)
end
exctract_plr(sim::PLR_Simulation) = sim.results .|> extract_plr

function simulate!(s::PLR_Simulation; logger = progress_logger())
    with_logger(logger) do
        ProgressLogging.@progress name = "PLR Simulation" for i in eachindex(s.results)
            simpoint = s.results[i]
            # If this point already has a valid result, we skip it
            is_valid_result(simpoint) && continue
            (;load) = simpoint
            plr = compute_plr_result(s.params, load)
            s.results.plr[i] = plr
        end
    end
    return s
end
