

function mad_outliers(
    sample::Vector{T},
    thresh ::Float64 = 3.0
)::Vector{Bool} where {T <: AbstractUpdate}
    η::Float64  = median(price.(sample))
    Δ::Vector{Float64} = @. abs(sample - η)
    δη::Float64 = median(Δ) 
    z_score = @. 0.6745 * Δ / δη
    return z_score .> thresh
end