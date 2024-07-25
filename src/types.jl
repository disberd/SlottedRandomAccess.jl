"""
    abstract type SlottedRAScheme{N} end
Abstract type representing a slotted random access scheme. The type parameter
`N` represents the maximum number of replicas that the scheme can generate.

See also [`FixedRepSlottedRAScheme`](@ref)
"""
abstract type SlottedRAScheme{N} end
"""
    abstract type FixedRepSlottedRAScheme{N} end
Abstract type representing a slotted random access scheme with a fixed number of
replicas (e.g. CRDSA and MF-CRDSA). The type parameter `N` represents the number
of replicas.

See also [`CRDSA`](@ref), [`MF_CRDSA`](@ref)
"""
abstract type FixedRepSlottedRAScheme{N} <: SlottedRAScheme{N} end

"""
$TYPEDEF
Type representing the _Contention Resolution Diversity Slotted ALOHA_ (CRDSA)
scheme, with a number of replicas `N`.

This RA scheme was introduced in [this 2007 IEEE paper](https://doi.org/10.1109/TWC.2007.348337).

See also: [`MF_CRDSA`](@ref)
"""
struct CRDSA{N} <: FixedRepSlottedRAScheme{N} end

"""
    This strcut, when called, will simply return the tuple of Int numbers from `1` to `N`. It is used as the default _Callable_ when initializing the [`MF_CRDSA`](@ref) struct with no arguments
"""
struct EachTimeSlot{N} end
(::EachTimeSlot{N})() where N = ntuple(identity, Val{N}())

"""
$TYPEDEF
Type representing the _Multi-Frequency Contention Resolution Diversity Slotted ALOHA_ (MF-CRDSA) scheme, with a number of replicas `N`.

This RA scheme was introduced in [this 2017 IEEE paper](https://doi.org/10.1109/TCOMM.2017.2696952).

The scheme can support a number of time slots that is different than the number of replicas, though the originating paper only implements a scheme where one replica (and only one) is sent in each time slot.

!!! note
    When specifying the number of frame slots in the [`PLR_SimulationParameters`](@ref), the total number of slots in the frame (`nslots`) is assumed to be the product of time slots and frequency slots.

    So for example when putting `nslots = 100` in the [`PLR_SimulationParameters`](@ref) and using a MF-CRDSA scheme with `time_slots = 2`, the number of frequency slots is assumed to be `50`.

The assumed number of time slots and the function used to generate them randomly can be modified through the structure fields listed below.

# Fields
$TYPEDFIELDS

!!! note
    The current implementation still assumes that there is only a single replica per time slot, so while the `time_slots_function` is arbitrary, potentially wrong results will be returned if this is not the case.

# Constructors
    MF_CRDSA{N}()

Default construct, which assumes `N` time slots (so one per replica) and that one replica is sent in each time slot (randomizing over the frequency slots).

    MF_CRDSA{N}(n_time_slots::Int, time_slots_function)
More advanced constructor for the MF-CRDSA scheme, which allows specifying a number of time slots different than the number of replicas and the function to be used to generate randomly the time slots to use for each user in each frame.

## Example
The code below will generate a MF-CRDSA scheme with 2 replicas and 3 time slots, where the first time slot is always used for the first replica, while the second replica is sent randomly either in the 2nd or 3rd slot.
```julia-repl
julia> scheme = MF_CRDSA{2}(3, () -> (1, rand(2:3)))
```

See also: [`CRDSA`](@ref)
"""
struct MF_CRDSA{N, F} <: FixedRepSlottedRAScheme{N} 
    "The number of time slots in each RA frame for this MF-CRDSA scheme, must be a number equal or greater than the number of replicas `N`"
    n_time_slots::Int
    "This function is used to generate the time slots (between 1 and `time_slots`). It should be a function (or callable) that takes no argument and return an `NTuple{N, Int}` with the time slots of each replica (without repetitions)."
    time_slots_function::F
    # Inner constructor
    function MF_CRDSA{N}(time_slots::Int, time_slots_function::F) where {N, F} 
        N <= time_slots || throw(ArgumentError("The number of replicas ($N) cannot be greater than the number of time slots ($time_slots)"))
        new{N, F}(time_slots, time_slots_function)
    end
end
MF_CRDSA{N}() where N = MF_CRDSA{N}(N, EachTimeSlot{N}())

"""
    @enum ReplicaPowerStrategy SamePower IndependentPower

Enum used to specify how the power for replicas of a given user in a specific RA frame is determined.

# Values
- `SamePower`: All replicas have the same power for a given user in a specific RA frame.
- `IndependentPower`: Each replica has an independent power in each slot.
"""
@enum ReplicaPowerStrategy SamePower IndependentPower

"""
    struct UserRealization{N, RA <: SlottedRAScheme}
Specifies the realization of replicas slots and replicas powers for a single
user in a single slotted RA frame. The parameter `N` specifies the maximum
number of replicas that the scheme of type `RA` can generate.

# Fields
$TYPEDFIELDS

# Constructor
The main constructor to use has the following form:
```julia
UserRealization(scheme::SlottedRAScheme, nslots::Int; power_dist, power_strategy::ReplicaPowerStrategy)
```
And internally computes the slots and power realizations for the user in the current frame.
"""
struct UserRealization{N,RA<:SlottedRAScheme{N},D}
    "The RA scheme used for the frame. Only used at construction to generate the slots and powers."
    scheme::RA
    "The number of slots in the frame."
    nslots::Int
    "Distribution used to generate the random power values"
    power_dist::D
    "The strategy to assign power to the replicas of a given packet. Must be a valid value of [`ReplicaPowerStrategy`](@ref) enum type."
    power_strategy::ReplicaPowerStrategy
    "A Tuple of `N` NamedTuples (where `N` is the max number of replicas of the scheme), each containing the slot idx and power of each replica."
    slots_powers::NTuple{N,@NamedTuple{slot::Int, power::Float64}}
end
function UserRealization(scheme::SlottedRAScheme, nslots::Int; power_dist, power_strategy=SamePower)
    slots_powers = replicas_slots_powers(scheme, nslots; power_dist, power_strategy)
    UserRealization(scheme, nslots, power_dist, power_strategy, slots_powers)
end

"""
$TYPEDEF
Type storing the parameters to be used for a PLR simulation.

# Fields
$TYPEDFIELDS
"""
@kwdef struct PLR_SimulationParameters{RA,F}
    "The specific RA scheme"
    scheme::RA
    "Flag specifying whether the simulation should assume poisson or constant traffic"
    poisson::Bool = true
    "The coderate of the packets sent by the users"
    coderate::Float64 = 1 / 3
    "The modulation cardinality of the packets sent by the users"
    M::Int = 4
    "Distribution used to generate the random power values"
    power_dist
    "The strategy to assign power to the replicas of a given packet. Must be a valid value of [`ReplicaPowerStrategy`](@ref) enum type."
    power_strategy::ReplicaPowerStrategy = SamePower
    "The number of RA frames to simulate for each Load point"
    max_simulated_frames::Int = 10^5
    "The number of slots in each RA frame"
    nslots::Int
    "The function used to compute the PLR for a given packet as a function of its equivalent Eb/N0"
    plr_func::F = default_plr_function(coderate)
    "The variance of the noise, assumed as N0 in the simulation"
    noise_variance::Float64 = 1.0
    "The maximum number of SIC iterations to perform during the decoding steps"
    SIC_iterations::Int = 15
    "The maximum number of frames with errors to simulate. Once a simulation reaches this number of frames with errors, the simulation will stop."
    max_errored_frames::Int = 10^4
end
# We do a default positional constructor which promote types
function PLR_SimulationParameters(scheme, poisson::Bool, coderate::Real, M::Real, power_dist, power_strategy::ReplicaPowerStrategy, max_simulated_frames::Real, nslots::Real, plr_func, noise_variance::Real, SIC_iterations::Real, max_errored_frames::Real)
    coderate = Float64(coderate)
    M = Int(M)
    max_simulated_frames = Int(max_simulated_frames)
    nslots = Int(nslots)
    noise_variance = Float64(noise_variance)
    SIC_iterations = Int(SIC_iterations)
    max_errored_frames = Int(max_errored_frames)
    return PLR_SimulationParameters(scheme, poisson, coderate, M, power_dist, power_strategy, max_simulated_frames, nslots, plr_func, noise_variance, SIC_iterations, max_errored_frames)
end

"""
$TYPEDSIGNATURES
Type to store the result of a PLR simulation run

# Fields
$TYPEDFIELDS
"""
@kwdef struct PLR_Result
    "The number of frames simulated for this PLR result"
    simulated_frames::Int = 0
    "The number of frames with errors within the simulation"
    errored_frames::Int = 0
    "The total number of decoded packets in the simulations, ignoring replicas"
    total_decoded::Int = 0
    "The total number of sent packets, ignoring replicas"
    total_sent::Int = 0
end
struct PLR_Simulation_Point
    "Normalized MAC Load at which the PLR result was computed"
    load::Float64
    "PLR result of the simulation"
    plr::PLR_Result
end
PLR_Simulation_Point(load::Real) = PLR_Simulation_Point(Float64(load), PLR_Result())

"""
$TYPEDEF
Type containing the parameters and results of a PLR simulation.

# Fields
$TYPEDFIELDS

# Constructors
    PLR_Simulation(load::AbstractVector; kwargs...)
Create a `PLR_Simulation` object by simply providing the load vector. This forwards all the `kwargs` to the [`PLR_SimulationParameters`](@ref) constructor.

    PLR_Simulation(load::AbstractVector, params::PLR_SimulationParameters; scatter_kwargs = Dict{Symbol, Any}())
This constructor permits to provide both the load and the `params` field directly as positional arguments. The custom keyword arguments to pass to the `scatter` call from PlotlyBase can be provided using the `scatter_kwargs` keyword argument, which defaults to an empty `Dict`.

See also: [`PLR_SimulationParameters`](@ref)
"""
struct PLR_Simulation
    "Parameters used for the simulation"
    params::PLR_SimulationParameters
    "Results of the simulation"
    results::StructArray{PLR_Simulation_Point}
    "The list of keyword arguments passed to the scatter call for plotting"
    scatter_kwargs::Dict{Symbol, Any}
    # We do this custom inner constructor to convert the scatter_kwargs to Dict{Symbol, Any}, so that you can also pass it anything that can be converted to it
    function PLR_Simulation(params::PLR_SimulationParameters, results::StructArray{PLR_Simulation_Point}, scatter_kwargs)
        dict = Dict{Symbol, Any}(scatter_kwargs)
        new(params, results, dict)
    end
end
function PLR_Simulation(load::AbstractVector; kwargs...)
    params = PLR_SimulationParameters(; kwargs...)
    PLR_Simulation(load, params)
end
function PLR_Simulation(load::AbstractVector, params::PLR_SimulationParameters; scatter_kwargs = Dict{Symbol, Any}())
    # We create the results as an unwrapped structarray so it's easy to access any of the fields
    results = StructArray(map(l -> PLR_Simulation_Point(l), load); unwrap=T -> !(T <: Real))
    PLR_Simulation(params, results, scatter_kwargs)
end