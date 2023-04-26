using Parquet
using PlotlyJS
using Dates

timeticks = convert.(
                TimeTick,
                CSV.File("data/IVE_tickbidask.txt",
                        delim = ",",
                        header = [:date, :time, :price, :bid, :ask, :size],
                        types = String
                )
            )

vol_bars = generate_volume_bars(timeticks, 500000000)
tick_bars = generate_tick_bars(timeticks, 5000)
length(timeticks)

vol_bars |> length

using PlotlyJS
            