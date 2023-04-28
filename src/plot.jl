#=
    plot.jl
=#

function plot(bars::Vector{T}) where {T <: AbstractBar}
    PlotlyJS.plot(
        PlotlyJS.candlestick(
        x = 1:length(getfield.(bars, :timestamp)),
        open = getfield.(getfield.(bars, :ohlc), :open),
        high = getfield.(getfield.(bars, :ohlc), :high),
        low = getfield.(getfield.(bars, :ohlc), :low),
        close = getfield.(getfield.(bars, :ohlc), :close)
        ),
        config=PlotConfig(staticPlot=true)
    ) 
end 