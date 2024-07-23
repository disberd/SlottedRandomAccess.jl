@testitem "Basics" begin
    using SlottedRandomAccess
    using SlottedRandomAccess: replicas_positions
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
end