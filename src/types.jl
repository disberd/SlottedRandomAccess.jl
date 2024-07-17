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
    @enum ReplicaPowerStrategy SamePower IndependentPower

Enum used to specify how the power for replicas of a given user in a specific RA frame is determined.

# Values
- `SamePower`: All replicas have the same power for a given user in a specific RA frame.
- `IndependentPower`: Each replica has an independent power in each slot.
"""
@enum ReplicaPowerStrategy SamePower IndependentPower

"""
    struct CRDSA{N, D} <: FixedRepSlottedRAScheme{N}
Type representing the _Contention Resolution Diversity Slotted ALOHA_ (CRDSA) scheme, with a number of replicas `N`.
This RA scheme was introduced in [this 2007 IEEE paper](https://doi.org/10.1109/TWC.2007.348337).

# Fields
- `power_dist::D`: The distribution used to create random samples of the replicas power.
- `replica_power::ReplicaPower`: Specifies how to sample the replicas power within a given RA frame for each user.

# Constructors
Apart from the standard `@kwdef` constructor with fully specified type
parameters (`N` and `D`), the two following constructor for specifying only the
number of replicas `N` are available:
- `CRDSA{N}(power_dist::D, args...)`: Creates a CRDSA scheme with `N` replicas \
and the power distribution `power_dist` and all other arguments forwarded to the \
default constructor.
- `CRDSA{N}(; power_dist::D, kwargs...)`: Creates a CRDSA scheme with `N` \
replicas and the power distribution `power_dist`, forwarding all other keyword \
arguments to the `@kwdef` default constructor.
"""
@kwdef struct CRDSA{N, D} <: FixedRepSlottedRAScheme{N}
    power_dist::D
    replica_power_strategy::ReplicaPowerStrategy = SamePower
end
CRDSA{N}(dist::D, args...) where {N, D} = CRDSA{N, D}(dist, args...)
CRDSA{N}(; power_dist::D, kwargs...) where {N,D} = CRDSA{N,D}(; power_dist, kwargs...)

"""
    struct MF_CRDSA{N, D} <: FixedRepSlottedRAScheme{N}
Type representing the _Multi-Frequency Contention Resolution Diversity Slotted ALOHA_ (MF-CRDSA) scheme, with a number of replicas `N`.
This RA scheme was introduced in [this 2017 IEEE paper](https://doi.org/10.1109/TCOMM.2017.2696952).

# Fields
- `power_dist::D`: The distribution used to create random samples of the replicas power.
- `replica_power::ReplicaPower`: Specifies how to sample the replicas power within a given RA frame for each user.

# Constructors
Apart from the standard `@kwdef` constructor with fully specified type
parameters (`N` and `D`), the two following constructor for specifying only the
number of replicas `N` are available:
- `MF_CRDSA{N}(power_dist::D, args...)`: Creates a MF-CRDSA scheme with `N` replicas \
and the power distribution `power_dist` and all other arguments forwarded to the \
default constructor.
- `MF_CRDSA{N}(; power_dist::D, kwargs...)`: Creates a MF-CRDSA scheme with `N` \
replicas and the power distribution `power_dist`, forwarding all other keyword \
arguments to the `@kwdef` default constructor.
"""
@kwdef struct MF_CRDSA{N, D} <: FixedRepSlottedRAScheme{N}
    power_dist::D
    replica_power_strategy::ReplicaPowerStrategy = SamePower
end
MF_CRDSA{N}(dist::D, args...) where {N, D} = MF_CRDSA{N, D}(dist, args...)
MF_CRDSA{N}(; power_dist::D, kwargs...) where {N,D} = MF_CRDSA{N,D}(; power_dist, kwargs...)

"""
    struct UserRealization{N, RA <: SlottedRAScheme}
Specifies the realization of replicas slots and replicas powers for a single
user in a single slotted RA frame. The parameter `N` specifies the maximum
number of replicas that the scheme of type `RA` can generate.

# Fields
- `scheme::RA`: The RA scheme used for the frame. Only used at construction to generate the slots and powers.
- `nslots::Int`: The number of slots in the frame.
- `slots::NTuple{N, Tuple{Int, Float64}}`: The slots positions for this user in the frame. Only non-zero values are considered valid positions for replicas to send
- `powers::NTuple{N, Float64}`: The powers of this user's packet replicas in the frame. Only non-NaN values are considered valid powers

# Constructor
The main constructor to use should accept just the `scheme` and the number of slots in the frame `nslots`.
It should internally generate the random realization of the slots positions and powers for the specific user in the current frame.
"""
struct UserRealization{N, RA <: SlottedRAScheme}
    scheme::RA
    nslots::Int
    slots_powers::NTuple{N, @NamedTuple{slot::Int, power::Float64}}
end
function UserRealization(scheme::SlottedRAScheme, nslots::Int)
    slots_powers = replicas_slots_powers(scheme, nslots)
    UserRealization(scheme, nslots, slots_powers)
end