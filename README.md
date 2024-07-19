# SlottedRandomAccess
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://disberd.github.io/SlottedRandomAccess.jl/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://disberd.github.io/SlottedRandomAccess.jl/dev)
[![Build Status](https://github.com/disberd/SlottedRandomAccess.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/disberd/SlottedRandomAccess.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![](https://img.shields.io/badge/%F0%9F%9B%A9%EF%B8%8F_tested_with-JET.jl-233f9a)](https://github.com/aviatesk/JET.jl)


This repository implements the simulations tools for computing the Packet Loss Ratio (PLR) of slotted random access schemes.

The following schemes are currently supported:
- **CRDSA**: Contention Resolution Diversity Slotted ALOHA, introduced in [this 2007 IEEE paper](https://doi.org/10.1109/TWC.2007.348337)
- **MF-CRDSA**: Multi-Frequency Contention Resolution Diversity Slotted ALOHA, introduced in [this 2017 IEEE paper](https://doi.org/10.1109/TCOMM.2017.2696952)

## Example Usage
To reproduce the 3-replicas curves of Fig. 8 in the [2017 paper]((https://doi.org/10.1109/TCOMM.2017.2696952)), one can use the following code block example:
```julia
using SlottedRandomAccess
using PlotlyBase # This is not part of the package env
# Generic parameters
common = (;M = 4, coderate = 1/3, power_strategy = SamePower)
coding_gain = common.coderate * log2(common.M) |> x -> -10log10(x)
line_colors = [ # Use to match the line colors
  "rgb(93, 146, 191)", # 6dB, blue
  "rgb(233, 71, 72)", # 9dB, red
  "rgb(113, 191, 109)", # 12dB, green
]
ebno_max_vec = [6,9,12]
# Define the load vector
load = .1:.1:2


### Create the CRDSA simulations
crdsa_sims = map(1:3) do idx
  ebno_max = ebno_max_vec[idx]
  line_color = line_colors[idx]
  # Define the RA scheme to use
  scheme = CRDSA{3}()
  # Define the power distribution for the replicas
  power_dist = LogUniform_dB(2 - coding_gain, ebno_max - coding_gain)
  # Create the simulation object
  sim = PLR_Simulation(load;
    common...,
    power_dist,
    scheme,
    nslots = 100,
  )
  # Add information to customize the plot to the simulation object
  add_scatter_kwargs!(sim; 
    name = "N<sub>rep</sub> = 3, [E<sub>b</sub>N<sub>0</sub>]<sub>max</sub> = $(ebno_max)dB",
    line_color,
    line_dash = :solid,
    marker_symbol = :square,
  )
  simulate!(sim) # Compute the packet loss ratio
end


### Create the MF-CRDSA curves
mf_crdsa_sims = map(1:3) do idx
  ebno_max = ebno_max_vec[idx]
  line_color = line_colors[idx]
  # Define the RA scheme to use
  scheme = MF_CRDSA{3}()
  # Define the power distribution for the replicas
  power_dist = LogUniform_dB(2 - coding_gain, ebno_max - coding_gain)
  # Create the simulation object
  sim = PLR_Simulation(load;
    common...,
    power_dist,
    scheme,
    nslots = 99,
  )
  # Add information to customize the plot to the simulation object
  add_scatter_kwargs!(sim; 
    name = "MF, N<sub>rep</sub> = 3, [E<sub>b</sub>N<sub>0</sub>]<sub>max</sub> = $(ebno_max)dB",
    line_color,
    line_dash = :dash,
    marker_symbol = :diamond
  )
  simulate!(sim) # Compute the packet loss ratio
end


# Plot the MF-CRDSA and CRDSA curves together
Plot(vcat(crdsa_sims, mf_crdsa_sims))
```