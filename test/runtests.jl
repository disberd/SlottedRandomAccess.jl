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