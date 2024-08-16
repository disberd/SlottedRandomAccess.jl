@testitem "PlotlyBase Extension tests" begin
    using PlotlyBase
    using SlottedRandomAccess
    using Distributions
    using Test

    power_dist = Dirac(5)

    scheme = RA4Step(10000, 2; freq_slots = 1, limit_packets = false)
    sim_1 = PLR_Simulation([2]; scheme, power_dist, coderate=1/2, plr_func = CollisionModel(), poisson = false, max_simulated_frames = 100)
    simulate!(sim_1)

    layout_1 = Plot(sim_1; xtype = :packets).layout;
    @test layout_1.xaxis_title_text == "Average Load (packets/slot)"

    layout_2 = Plot(sim_1; xtype = :speff).layout;
    @test layout_2.xaxis_title_text == "Average Load, G (bits/symbol)"

    @test_throws "`xtype`" Plot(sim_1; xtype = :asd).layout; 
    @test_throws "`xtype`" scatter(sim_1, :asd)
end