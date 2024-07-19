using TestItemRunner

@testitem "Aqua" begin
    using Aqua
    using SlottedRandomAccess
    #= 
    Unfortunately we have deps with ambiguities, so the amibiguities test will
    fail for reasons not directly related to this packages's code.
    We separately test for ambiguities alone on the package, as suggested in one
    comment in https://github.com/JuliaTesting/Aqua.jl/issues/77. Not sure whether
    this is actually correctly identifying ambiguities from this package alone.
    =#
    Aqua.test_all(SlottedRandomAccess; ambiguities=false)
    Aqua.test_ambiguities(SlottedRandomAccess)
end

@testitem "JET" begin
    using JET
    using SlottedRandomAccess
    report_package("SlottedRandomAccess")
end

@testitem "Reduced Readme Example" begin
    using SlottedRandomAccess
    using PlotlyBase # This is not part of the package env
    # Generic parameters
    common = (; M=4, coderate=1 / 3, power_strategy=SamePower)
    coding_gain = common.coderate * log2(common.M) |> x -> -10log10(x)
    line_colors = [ # Use to match the line colors
        "rgb(93, 146, 191)", # 6dB, blue
        "rgb(233, 71, 72)", # 9dB, red
        "rgb(113, 191, 109)", # 12dB, green
    ]
    ebno_max_vec = [6, 9, 12]
    # Define the load vector
    load = 0.1:0.1:.2
    # Create the CRDSA curves
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
            nslots=100,
        )
        add_scatter_kwargs!(sim;
            name="N<sub>rep</sub> = 3, [E<sub>b</sub>N<sub>0</sub>]<sub>max</sub> = $(ebno_max)dB",
            line_color,
            line_dash=:solid,
            marker_symbol=:square,
        )
        simulate!(sim) # Compute the packet loss ratio
    end
    # Create the MF-CRDSA curves
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
            nslots=99,
        )
        # Add information to customize the plot to the simulation object
        add_scatter_kwargs!(sim;
            name="MF, N<sub>rep</sub> = 3, [E<sub>b</sub>N<sub>0</sub>]<sub>max</sub> = $(ebno_max)dB",
            line_color,
            line_dash=:dash,
            marker_symbol=:diamond
        )
        simulate!(sim) # Compute the packet loss ratio
    end
    # Plot the MF-CRDSA and CRDSA curves together
    Plot(vcat(crdsa_sims, mf_crdsa_sims))
end

@run_package_tests verbose=true