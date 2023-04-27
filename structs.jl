#=
    structs.jl
=#
abstract type FinancialDataStructure end
abstract type AbstractBar <:FinancialDataStructure end

struct TimeTick 
    timestamp   ::DateTime
    price       ::Float64
    bid         ::Float64
    ask         ::Float64
    size        ::Int64
end

function price(tick::TimeTick)::Float64
    getfield(tick, :price)
end

function volume(tick::TimeTick)::Float64
    price(tick) * getfield(tick, :size)
end

function timestamp(tick::TimeTick)::DateTime
    getfield(tick, :timestamp)
end
    
struct OHLC
    open    ::Float64
    high    ::Float64
    low     ::Float64
    close   ::Float64
end

struct VolumeBar    <:AbstractBar
    timestamp::DateTime
    ohlc::OHLC
end

struct CurrencyBar  <:AbstractBar 
    timestamp::DateTime
    ohlc::OHLC
end

struct TickBar      <:AbstractBar
    timestamp::DateTime
    ohlc::OHLC
end

struct TimeBar      <:AbstractBar
    timestamp::DateTime
    ohlc::OHLC
end

using CSV


function Base.convert(::Type{TimeTick}, row::CSV.Row)::TimeTick
    dt = DateTime(join([replace(row.date, "/" => "-"), row.time], " ") ,  dateformat"m-d-Y H:M:S")
    TimeTick(
        dt,
        parse(Float64, row.price),
        parse(Float64, row.bid),
        parse(Float64, row.ask),
        parse(Int64,  row.size)
    )
end

function generate_volume_bars(
    ticks::Vector{TimeTick},
    target_volume::Union{Float64, Int64}
)::Vector{VolumeBar}
    volbars = similar(ticks, VolumeBar)
    accumulated_volume::Float64 = 0.0;
    last_idx = 1;
    bar_counter = 1;
    for (idx, tk) in enumerate(ticks)
        accumulated_volume += volume(tk)
        if accumulated_volume >= target_volume
            open, close = price(ticks[last_idx]), price(ticks[idx])
            high, low = extrema(price, ticks[last_idx:idx])
            ts = timestamp(ticks[idx])
            volbars[bar_counter] = VolumeBar(ts, OHLC(open, high, low, close))
            accumulated_volume = 0.0
            last_idx =  idx + 1
            bar_counter += 1
        end
    end
    resize!(volbars, bar_counter - 1)
end

function generate_tick_bars(
    ticks::Vector{TimeTick},
    target_tick_number::Int64
)::Vector{TickBar}
    tickbars = similar(ticks, TickBar)
    accumulated_tick_count::Int64 = 0;
    last_idx = 1;
    bar_counter = 1;
    for (idx, tk) in enumerate(ticks)
        accumulated_tick_count += 1
        if accumulated_tick_count >= target_tick_number
            open, close = price(ticks[last_idx]), price(ticks[idx])
            high, low = extrema(price, ticks[last_idx:idx])
            ts = timestamp(ticks[idx])
            tickbars[bar_counter] = TickBar(ts, OHLC(open, high, low, close))
            accumulated_tick_count = 0
            last_idx =  idx + 1
            bar_counter += 1
        end
    end
    resize!(tickbars, bar_counter - 1)
end

function generate_currency_bars(
    ticks::Vector{TimeTick},
    target_value::Union{Float64, Int64}
)::Vector{VolumeBar}
    volbars = similar(ticks, CurrencyBar)
    accumulated_currency::Float64 = 0.0;
    last_idx = 1;
    bar_counter = 1;
    for (idx, tk) in enumerate(ticks)
        accumulated_currency += price(tk)
        if accumulated_volume >= target_value
            open, close = price(ticks[last_idx]), price(ticks[idx])
            high, low = extrema(price, ticks[last_idx:idx])
            ts = timestamp(ticks[idx])
            volbars[bar_counter] = VolumeBar(ts, OHLC(open, high, low, close))
            accumulated_currency = 0.0
            last_idx =  idx + 1
            bar_counter += 1
        end
    end
    resize!(volbars, bar_counter - 1)
end

