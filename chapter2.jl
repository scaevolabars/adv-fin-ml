begin 
	using CSV
	using Parquet
	using DataFrames
	using Dates
    using Plots
    using StatsBase
    using StatsPlots
    using PlotlyJS
end
gr();


# Data loading pipeline
begin
    colnames = [:date, :time, :price, :bid, :ask, :size]
    df = CSV.read(
            "./data/IVE_tickbidask.txt",
            DataFrame,
            types =  String, 
            header = colnames
        )
end

begin
	transform!(df, 
		:date => ByRow(x -> replace(x, "/" => "-")) => :date,
	    :price      =>  ByRow(x -> parse(Float64, x)) => :price,
	    :bid        =>  ByRow(x -> parse(Float64, x)) => :bid,
		:ask        =>  ByRow(x -> parse(Float64, x)) => :ask,
        :size       =>  ByRow(x -> parse(Float64, x)) => :size
	)
	transform!(df,
     [:date, :time] =>  ByRow((x,y) -> x * " " * y) => :timetick
    )
	transform!(df, 
		:timetick  =>   ByRow(x -> DateTime.(x,  dateformat"m-d-Y H:M:S"))
				   => :timetick
	) 
	select!(df, Not([:date, :time]))
end

"""
    mad_outliers(
    sample::Vector{T},
    thresh::Float64 = 3.0)::Vector{Bool} where {T <: Real}

Calculates indices of the Median Absolute Deviation outliers
"""
function mad_outliers(
    sample::Vector{T},
    thresh ::Float64 = 3.0)::Vector{Bool} where {T <: Real}
    η::Float64  = median(sample)
    Δ::Vector{Float64} = @. abs(sample - η)
    δη::Float64 = median(Δ) 
    z_score = @. 0.6745 * Δ / δη
    return z_score .> thresh
end

#-Outlier Detecion-#
mask = mad_outliers(df.price)
boxplot(
    df[Not(mask), :price],
    linewidth=2,
    label = "Outlies removed"
)
boxplot!(
    df.price,
    linewidth=2,
    label = "With outliers"
)
#------------------#

#-Remove outliers-#
df = df[Not(mask), :]
#-----------------#


#= 
#-Save to .parquet-#

# Parquet.jl yet doesn't support DateTime conversion so conversion to String is necessary
parquet_df = transform(
    df,
    :timetick => ByRow(x -> Dates.format(x, "yyyy-mm-dd HH:MM:SS")) => :timetick 
    )
parquet_df    
write_parquet("data/s&p500_bid_ask_tickdata", parquet_df)
=#

# Tick bars

const TICK_SAMPLE_SIZE = 10000


#TODO write optimal bar calculation routine
function tick_bars(df::DataFrame)::DataFrame
    insertcols(
        df,
        1,
        :tick_group => div.(rownumber.(eachrow(df)),
        TICK_SAMPLE_SIZE)
    )
end

function tick_bars_dataframe(frame::DataFrame)::DataFrame
    combine(
        groupby(frame, :tick_group),
        :price => last => :close,
        :price => last => :open,
        :price => maximum => :high,
        :price => minimum => :low,
        :timetick => last => :timetick
    )
end
    
tb = tick_bars(df)
tb = tick_bars_dataframe(tb)


#TODO add details to the graph
PlotlyJS.plot(PlotlyJS.candlestick(
    open = tb.open,
    high = tb.high,
    low = tb.low,
    close = tb.close
),
config=PlotConfig(responsive=false)
)





