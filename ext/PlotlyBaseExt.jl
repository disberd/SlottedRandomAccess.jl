module PlotlyBaseExt

using PlotlyBase: Layout, scatter, Plot, attr, PlotlyBase
using SlottedRandomAccess: default_layout, SlottedRandomAccess, PLR_Simulation, extract_plr, compute_coding_gain

const PLOTLY_DEFAULT_LAYOUT = Layout()

function empty_layout(; kwargs...)
    layout = Layout(; kwargs...)
    for key in keys(PLOTLY_DEFAULT_LAYOUT.fields)
        # If a key was not explicitly provided to override, we remove the default value from the default layout
        haskey(kwargs, key) || delete!(layout.fields, key)
    end
    return layout
end

function SlottedRandomAccess.default_layout(s::PLR_Simulation; xtype = :speff, kwargs...)
    default = Layout(;
        template="none",
        yaxis=attr(;
            type="log",
            minor=attr(;
                showgrid=true,
                dtick="D1",
                griddash="dot",
                nticks=10,
                gridcolor="rgba(0,0,0, .2)",
            ),
            dtick=1,
            gridcolor="rgba(0,0,0, .2)",
            range=[-5, 0],
            exponentformat="power",
            tickfont=attr(;
                family="Computer Modern",
            ),
            title=attr(;
                text="Packet Loss Ratio",
                font=attr(;
                    family="Computer Modern",
                    size=16,
                ),
            ),
        ),
        xaxis=attr(;
            tickfont=attr(;
                family="Computer Modern",
                size=15,
            ),
            title=attr(;
                text= if xtype === :speff
                    "Average Load, G (bits/symbol)"
                elseif xtype === :packets
                    "Average Load (packets/slot)"
                else
                    error("The second `xtype` kwarg can only be `:speff` or `:packets`")
                end,
                font=attr(;
                    family="Computer Modern",
                    size=16,
                ),
                stadnoff=5,
            ),
        ),
        legend=attr(;
            x=0.97,
            xanchor="right",
            y=0.03,
            font=attr(;
                family="Computer Modern",
                size=13,
            ),
            borderwidth=1,
        )
    )
    override = empty_layout(; kwargs...)
    out = merge(default, override)
    return out
end

"""
    scatter(sim::PLR_Simulation; kwargs...)
Creates a scatter using the load values as X and the PLR values as Y.

All kwargs are forwarded to the internal `scatter` call.
"""
function PlotlyBase.scatter(sim::PLR_Simulation, xtype::Symbol = :speff; kwargs...)
    x = sim.results.load
    if xtype === :speff
    elseif xtype === :packets
        coding_gain = compute_coding_gain(sim)
        x .* coding_gain
    else 
        error("The second arugment (`xtype`) can only be `:speff` or `:packets`")
    end
    y = sim.results .|> extract_plr
    return scatter(; x, y, mode="lines+markers", sim.scatter_kwargs..., kwargs...)
end

PlotlyBase.Plot(sims::AbstractVector{<:PLR_Simulation}, layout::Layout; xtype = :speff, kwargs...) = Plot(map(Base.Fix2(scatter, xtype), sims), layout; kwargs...)
PlotlyBase.Plot(sims::AbstractVector{<:PLR_Simulation}; xtype = :speff, kwargs...) = Plot(sims, default_layout(first(sims); xtype, kwargs...); xtype)
function PlotlyBase.Plot(sim::PLR_Simulation, args...; kwargs...)
    @nospecialize
    Plot([sim], args...; kwargs...)
end

end