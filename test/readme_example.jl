@testitem "Reduced Readme Example" begin
    using SlottedRandomAccess
    using Test
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
    load = [.6, .8, 1, 1.2]
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

    # We test that the points computed are in the range to be similar to the paper results
    load_idx = 1 # 0.6 load
    @test extract_plr(crdsa_sims[1].results[load_idx]) > 9e-5 # 0.6 load
    @test extract_plr(mf_crdsa_sims[1].results[load_idx]) > 1e-4 # 0.6 load
    @test all(2:3) do ebno_max_idx
        extract_plr(crdsa_sims[ebno_max_idx].results[load_idx]) < 1e-4 # 0.6 load
    end
    @test all(2:3) do ebno_max_idx
        extract_plr(mf_crdsa_sims[ebno_max_idx].results[load_idx]) < 1e-4 # 0.6 load
    end

    load_idx = 2 # 0.8 load
    for sim in (crdsa_sims[1], mf_crdsa_sims[1])
        @test .05 < extract_plr(sim.results[load_idx]) < .1 # 0.8 load
    end
    @test extract_plr(crdsa_sims[2].results[load_idx]) < 1e-4 # 0.8 load
    @test extract_plr(mf_crdsa_sims[2].results[load_idx]) > 1e-4 # 0.8 load

    @test extract_plr(crdsa_sims[3].results[load_idx]) < 1e-4 # 0.8 load
    @test extract_plr(mf_crdsa_sims[3].results[load_idx]) < 1e-4 # 0.8 load

    load_idx = 3 # 1 load
    for sim in (crdsa_sims[1], mf_crdsa_sims[1])
        @test extract_plr(sim.results[load_idx]) > .5 # 1 load
    end
    for sim in (crdsa_sims[2], mf_crdsa_sims[2])
        @test 1e-2 < extract_plr(sim.results[load_idx]) < 4e-2 # 1 load
    end
    for sim in (crdsa_sims[3], mf_crdsa_sims[3])
        @test extract_plr(sim.results[load_idx]) < 1e-4 # 1 load
    end

    load_idx = 4 # 1.2 load
    for sim in (crdsa_sims[1], mf_crdsa_sims[1])
        @test extract_plr(sim.results[load_idx]) > .8 # 1.2 load
    end
    for sim in (crdsa_sims[2], mf_crdsa_sims[2])
        @test .4 < extract_plr(sim.results[load_idx]) < .5 # 1.2 load
    end
    for sim in (crdsa_sims[3], mf_crdsa_sims[3])
        @test .9e-2 < extract_plr(sim.results[load_idx]) < 1.1e-2 # 1.2 load
    end

    # Plot the MF-CRDSA and CRDSA curves together
    Plot(vcat(crdsa_sims, mf_crdsa_sims))
end