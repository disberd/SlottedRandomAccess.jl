"""
    max_replicas(s::SlottedRAScheme)
This function returns the maximum number of replicas that a given scheme can generate.
"""
max_replicas(::FixedRepSlottedRAScheme{N}) where {N} = N

"""
    replicas_positions(::FixedRepSlottedRAScheme{N}, nslots::Int)

Returns a tuple of `N` integers representing the slot positions of the replicas
for a specific user in a given RA frame with `nslots` slots.

For schemes not generating a constant number of replicas in each frame, the
returned Tuple will always have `N` values (with `N` being the maximum number of
replicas in the scheme).
The actual values of valid replica slots will be `effective_nreplicas <= N`, and
the elements of the returned tuple will be non-zero only for the first
`effective_nreplicas` values.

See also: [`replicas_power`](@ref)
"""
function replicas_positions end
# CRDSA version, creates N random independent slots between 1 and nslots
replicas_positions(::SlottedALOHA, nslots) = (rand(1:nslots),)
function replicas_positions(::CRDSA{N}, nslots) where N
	@no_escape begin
		a = @alloc(Int, N)
		for i in eachindex(a)
			a[i] = 0
			val = rand(1:nslots)
			@views while val ∈ a[1:i-1]
				val = rand(1:nslots)
			end
			a[i] = val
		end
		ntuple(i -> a[i], Val{N}())
	end
end
# MF-CRDSA version, creates N random slots, each falling into the respective partition of `nslots` into `N` non-overlapping groups
function replicas_positions(scheme::MF_CRDSA{N}, nslots) where N
    (;n_time_slots) = scheme # This is the number of assumed time slots in the frame
	@assert mod(nslots, n_time_slots) == 0 "The number of total slots must be a multiple of the number of time slots."
	offset = nslots ÷ n_time_slots
    # We enforce the return type so that we get an error if the provided generation function gives the wrong one
    tslots = scheme.time_slots_function()::NTuple{N, Int}
	return ntuple(Val{N}()) do i
		rand(1:offset) + (tslots[i]-1) * offset
	end
end

# This function expects a number of slots in input which is not the slots passed to the PLR_SimulationParameters contructor, but is just based on the parameters of the RA4Step function.
function replicas_positions(scheme::RA4Step, nslots) 
    @assert nslots == msg1_slots(scheme) "The number of slots passed to this function does not match the expected number of virtual slots for the specified scheme $(scheme)"
    replicas_positions(SlottedALOHA(), nslots)
end
msg1_slots(scheme::RA4Step) = scheme.msg1_occasions * scheme.freq_slots
msg3_slots(scheme::RA4Step) = scheme.msg3_occasions * scheme.freq_slots

"""
    replicas_power(::SlottedRAScheme, effective_nreplicas::Int)

Returns a tuple of `N` floats representing the power for each of the replicas.
For schemes which have a variable number of replicas, only the first
`effective_nreplicas` values are not `NaN`.
!!! note
    The power returned by this function represents a value in Watts.

See also: [`replicas_positions`](@ref)
"""
function replicas_power(::SlottedRAScheme{N}, effective_nreplicas::Int = N; power_dist, power_strategy) where N
    @assert effective_nreplicas === N "You can't specify a number of replicas that is different from the number of the fixed replicas scheme."
	n = Val{N}()
	if power_strategy === SamePower
		p = rand(power_dist)
		return ntuple(i -> i > effective_nreplicas ? NaN : p, n)
	elseif power_strategy === IndependentPower
		return ntuple(i -> i > effective_nreplicas ? NaN : rand(power_dist), n)
	else
		error("Unsupported type of replica power")
	end
end

"""
    replicas_slots_powers(::SlottedRAScheme{N})

Generate a tuple of `N` tuples `Tuple{Int, Float64}` representing 
"""
function replicas_slots_powers(s::SlottedRAScheme, nslots; power_dist, power_strategy)
    slots = replicas_positions(s, nslots)
    effective_nreplicas = sum(!iszero, slots)
    powers = replicas_power(s, effective_nreplicas; power_dist, power_strategy)
    map(slots, powers) do slot, power
        power = Float64(power)
        (;slot, power)
    end
end