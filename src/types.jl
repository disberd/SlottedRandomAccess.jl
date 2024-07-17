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
    struct CRDSA{N, D} <: FixedRepSlottedRAScheme{N}
Type representing the _Contention Resolution Diversity Slotted ALOHA_ (CRDSA)
scheme, with a number of replicas `N`.

This RA scheme was introduced in [this 2007 IEEE paper](https://doi.org/10.1109/TWC.2007.348337).

See also: [`MF_CRDSA`](@ref)
"""
struct CRDSA{N} <: FixedRepSlottedRAScheme{N} end

"""
$TYPEDEF
Type representing the _Multi-Frequency Contention Resolution Diversity Slotted ALOHA_ (MF-CRDSA) scheme, with a number of replicas `N`.

This RA scheme was introduced in [this 2017 IEEE paper](https://doi.org/10.1109/TCOMM.2017.2696952).

See also: [`CRDSA`](@ref)
"""
struct MF_CRDSA{N,D} <: FixedRepSlottedRAScheme{N} end

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
PLR_Simulation_Point(load::Float64) = PLR_Simulation_Point(load, PLR_Result())

"""
$TYPEDSIGNATURES
Type containing the parameters and results of a PLR simulation.
# Fields
$TYPEDFIELDS
"""
struct PLR_Simulation
    "Parameters used for the simulation"
    params::PLR_SimulationParameters
    "Results of the simulation"
    results::StructArray{PLR_Simulation_Point}
end
function PLR_Simulation(load::AbstractVector; kwargs...)
    params = PLR_SimulationParameters(; kwargs...)
    # We create the results as an unwrapped structarray so it's easy to access any of the fields
    results = StructArray(map(l -> PLR_Simulation_Point(l), load); unwrap=T -> T <: PLR_Simulation_Point)
    PLR_Simulation(params, results)
end