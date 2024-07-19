using Documenter
using SlottedRandomAccess

makedocs(
    authors="Alberto Mengali <disberd@gmail.com>",
    repo="https://github.com/disberd/SlottedRandomAccess.jl/blob/{commit}{path}#{line}",
    sitename="SlottedRandomAccess",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        edit_link="main",
        assets=String[],
    ),
    modules = Module[SlottedRandomAccess],
    warnonly = true,
)

# This controls whether or not deployment is attempted. It is based on the value
# of the `SHOULD_DEPLOY` ENV variable, which defaults to the `CI` ENV variables or
# false if not present.
should_deploy = get(ENV,"SHOULD_DEPLOY", get(ENV, "CI", "") === "true")

if should_deploy
    @info "Deploying"

deploydocs(
    repo = "github.com/disberd/SlottedRandomAccess.jl.git",
)

end