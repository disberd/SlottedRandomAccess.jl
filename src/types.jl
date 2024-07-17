"""
    abstract type SlottedRAScheme end
Abstract type representing a slotted random access scheme.

See also [`FixedRepSlottedRAScheme`](@ref)
"""
abstract type SlottedRAScheme end
"""
    abstract type FixedRepSlottedRAScheme{N} end
Abstract type representing a slotted random access scheme with a fixed number of
replicas (e.g. CRDSA and MF-CRDSA). The type parameter `N` represents the number
of replicas.

See also [`CRDSA`](@ref), [`MF_CRDSA`](@ref)
"""
abstract type FixedRepSlottedRAScheme{N} end
