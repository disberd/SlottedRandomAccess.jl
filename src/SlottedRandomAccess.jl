module SlottedRandomAccess

using Polynomials
using Distributions
using Random 
using Bumper
using StructArrays
using DocStringExtensions

# from types.jl
export PLR_Simulation, PLR_SimulationParameters, CRDSA, MF_CRDSA
# from utils.jl
export LogUniform_dB, add_scatter_kwargs!
# from compute_plr
export compute_plr, compute_plr!

include("types.jl")
include("interface_functions.jl")
include("utils.jl")
include("phy_abstraction.jl")
include("compute_plr.jl")

end # module SlottedRandomAccess
