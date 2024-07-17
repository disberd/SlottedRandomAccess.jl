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

# Block actualy performing the decoding iterations
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

function compute_plr_result(params::PLR_SimulationParameters, load)
    (; scheme, poisson, coderate, M, max_simulated_frames, nslots, max_errored_frames) = params
    coding_gain = 1 / (coderate * log2(M))
    mean_users = nslots * load * coding_gain
    errored_frames = 0
    total_decoded = 0
    total_sent = 0
    for frame in 1:max_simulated_frames
        # Compute the effective number of users for this frame
        nusers = poisson ? rand(Poisson(mean_users)) : round(Int, mean_users)
        @no_escape begin
            # Initialize the vector of users
            users = @alloc(UserRealization{max_replicas(scheme),typeof(scheme)}, nusers)
            # Initialize the matrix of power allocations
            power_matrix = @alloc(Float64, nusers, nslots)
            # Make sure that power_matrix has all zeros
            fill!(power_matrix, zero(eltype(power_matrix)))
            # Instantiate the users for this frame
            for u in eachindex(users)
                users[u] = UserRealization(scheme, nslots)
            end
            # Populate the power_matrix with the power of the users replicas
            allocate_users!(power_matrix, users)
            ndecoded = process_frame!(power_matrix, users; params)
            total_decoded += ndecoded
            total_sent += nusers
            errored_frames += ndecoded > 0
        end
        # Break if we reached the max number of errored frames
        errored_frames >= max_errored_frames && break
    end
    plr_result = PLR_Result(;
        simulated_frames=max_simulated_frames,
        total_decoded,
        errored_frames,
        total_sent
    )
    # Compute the PLR for this load point
    return plr_result
end

# Compute the actual PLR value (between 0 and 1) from the PLR_Result structure
function compute_plr(r::PLR_Result)
    is_valid_result(r) || @warn "The provided PLR result does not seem to correspond to an actual simulation, as the number of simulated frames is 0"
    plr = 1 - r.total_decoded / r.total_sent
    return plr
end
compute_plr(params::PLR_SimulationParameters, load) = compute_plr_result(params, load) |> compute_plr
compute_plr(s::PLR_Simulation_Point) = compute_plr(s.plr)

function compute_plr!(s::PLR_Simulation)
    Threads.@threads for i in eachindex(s.results)
    end
end
