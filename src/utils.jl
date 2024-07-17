"""
    LogUniform_dB(min_db,max_db)
Defines a distribution whose pdf is uniform in dB between `min_db` and `max_db`.
"""
function LogUniform_dB(min_db,max_db)
	a = 10^(min_db/10)
	b = 10^(max_db/10)
	LogUniform(a,b)
end

# This functions take a matrix N_Users x N_slots and a vector of users and inserts the power of each replica in the slots for each user
function allocate_users!(power_matrix, users)
	@assert length(users) === size(power_matrix, 1) "Mismatch in matrix rows and number of users"
	# We start by putting everything to zero
	fill!(power_matrix, zero(eltype(power_matrix)))
	for u in eachindex(users) # Iterating over users
		for (;slot, power) in users[u].slots_powers
			power_matrix[u, slot] = power
		end
	end
	return power_matrix
end

# Check if a result is valid or is just an initialized but not ran simulation
is_valid_result(r::PLR_Result) = r.simulated_frames > 0