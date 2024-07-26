module SlottedRandomAccess

using Polynomials
using Distributions
using Random 
using Bumper
using StructArrays
using DocStringExtensions
using ChunkSplitters
using ProgressLogging
using Logging
using LoggingExtras
using TerminalLoggers
using ScopedValues

# from types.jl
export PLR_Simulation, PLR_SimulationParameters, CRDSA, MF_CRDSA, SamePower, IndependentPower, ReplicaPowerStrategy, GeneralizedLogistic
# from utils.jl
export LogUniform_dB, add_scatter_kwargs!
# from extract_plr
export extract_plr, simulate!

const NTASKS = ScopedValue(0)

include("types.jl")
include("interface_functions.jl")
include("utils.jl")
include("phy_abstraction.jl")
include("compute_plr.jl")

end # module SlottedRandomAccess
