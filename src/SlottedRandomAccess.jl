module SlottedRandomAccess

using Polynomials
using Distributions
using Random 
using Bumper
using StructArrays
using DocStringExtensions

include("types.jl")
include("interface_functions.jl")
include("utils.jl")
include("phy_abstraction.jl")
include("compute_plr.jl")

end # module SlottedRandomAccess
