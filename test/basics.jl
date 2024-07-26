@testitem "Basics" begin
    using SlottedRandomAccess
    using SlottedRandomAccess: replicas_positions, UserRealization
    using SlottedRandomAccess: default_plr_function, Turbo4G_K328_N576, Turbo4G_K328_N768
    using Distributions
    using Test

    scheme = MF_CRDSA{3}()

    @test_throws "a multiple of the number of time slots" replicas_positions(scheme, 100)

    test_vec = map(_ -> replicas_positions(scheme, 99), 1:10)
    @test all(test_vec) do (s1, s2, s3)
        s1 <= 33 &&
        33 < s2 <= 66 &&
        66 < s3 <= 99
    end

    scheme = MF_CRDSA{2}(3, () -> (1, rand(2:3)))
    test_vec = map((x) -> scheme.time_slots_function(), 1:10)
    @test all(x -> x[1] == 1, test_vec)
    second_time_slots = unique(map(x -> x[2], test_vec))
    @test sort(second_time_slots) == [2,3]

    @test_throws "cannot be greater than the number of time slots" MF_CRDSA{4}(3, () -> (1,2,3,4))

    # We test the implicit conversion when giving wrong parameters type (like Int to Float and viceversa)
    scheme = CRDSA{2}()
    power_dist = Dirac(3) # This has integer power which should be converted to Float64
    nslots = 100.0 # This should be int
    sim = PLR_Simulation(1:2; scheme, power_dist, nslots)
    p = sim.params
    @test p.nslots isa Int

    user = UserRealization(scheme, nslots; power_dist, power_strategy=SamePower)
    @test user.nslots isa Int
    @test user.slots_powers isa NTuple{<:Any, @NamedTuple{slot::Int, power::Float64}}

    # We run a simulation to make sure it doesn't error
    simulate!(sim)

    # Test the default plr works for the new fitted data
    @test default_plr_function(.57) === default_plr_function(328/576) === Turbo4G_K328_N576
    @test default_plr_function(.43) === default_plr_function(328/768) === Turbo4G_K328_N768
    @test_throws "Please provide manually" default_plr_function(.11)

    # Call some points in the fitted simulation to check the results are correct
    db2lin(x) = 10^(x/10)
    f(x) = Turbo4G_K328_N576(db2lin(x))
    @test f(0) > 0.98
    @test 0.7 > f(1) > 0.65
    @test 0.04 > f(2) > 0.03
    @test 6e-3 > f(2.5) > 2e-3
end

@testitem "Overhead" begin
    # This test just do some basic checks on the overhead parameter using the curves from the paper
    using SlottedRandomAccess
    using Test

    # Simulating with an overhead of 0.5 should be equivalent to assuming a 0 overhead but scaling the load by a factor 1.5
    common = (; M=4, coderate=1 / 3, power_strategy=SamePower)
    coding_gain = common.coderate * log2(common.M) |> x -> -10log10(x)
    power_dist = LogUniform_dB(2 - coding_gain, 6 - coding_gain)
    nslots = 100
    load = .7:.1:1 
    scheme = CRDSA{3}()
    # Do the simulation with normal load but overhead
    sim_overhead = PLR_Simulation(load; common..., power_dist, scheme, nslots, overhead=0.5)
    simulate!(sim_overhead)
    # Do the simulation with scaled load an no overhead, not provided as it defaults to 0
    sim_scaled = PLR_Simulation(load .* (1 + 0.5); common..., power_dist, scheme, nslots)
    simulate!(sim_scaled)

    for i in eachindex(load)
        plr_overhead = extract_plr(sim_overhead.results[i])
        plr_scaled = extract_plr(sim_scaled.results[i])
        @test isapprox(plr_overhead, plr_scaled; rtol = .1)
    end
end