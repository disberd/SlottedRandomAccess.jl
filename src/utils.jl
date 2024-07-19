Base.:+(p1::PLR_Result, p2::PLR_Result) = PLR_Result(
    p1.simulated_frames + p2.simulated_frames,
    p1.errored_frames + p2.errored_frames,
    p1.total_decoded + p2.total_decoded,
    p1.total_sent + p2.total_sent
)

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

const TERMINAL_LOGGER = Ref{TerminalLogger}()
function terminal_logger()
    isassigned(TERMINAL_LOGGER) && return TERMINAL_LOGGER[]
    TERMINAL_LOGGER[] = TerminalLogger()
end

# The default set of loggers passed for the progress_channesl, including both the default one and a custom TerminalLogger to also show progress outside of the VSCode progress bar.
progress_logger() = if isinteractive()
    # We only copy to the terminal logger the loggings from ProgresLogging.jl, which have a LogLevel of -1
    filtered_terminal = EarlyFilteredLogger(terminal_logger()) do log
        log.level == LogLevel(-1)
    end
    TeeLogger(current_logger(), filtered_terminal)
else
    current_logger()
end


# Check if a result is valid or is just an initialized but not ran simulation
is_valid_result(r::PLR_Result) = r.simulated_frames > 0
is_valid_result(s::PLR_Simulation_Point) = is_valid_result(s.plr)

"""
    default_layout(s::PLR_Simulation; kwargs...)
This function return a default layout for plotting the results of a PLR simulation. It can be used to customize the plot function if needed.

All passed keyword arguments are passed to the `Layout` constructor used inside the function, allowing the override default layout values.

By default this function has no method. A method is added in the relevant extension once PlotlyBase is loaded as dependency.
"""
function default_layout end

"""
    add_scatter_kwargs!(sim::PLR_Simulation; kwargs...)
Add arguments to the `scatter_kwargs` field in the simulation object by merging
all the passed keyword arguments with the existing dictionary.
"""
function add_scatter_kwargs!(sim::PLR_Simulation; kwargs...)
    merge!(sim.scatter_kwargs, kwargs)
    return sim
end