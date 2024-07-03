module LinearModel

using Random, Statistics, ProgressBars

export Perceptron, Adaline

abstract type AbstractModel end

# Activation functions
"""Linear activation function"""
linearactivation(X) = X

# Common methods
"""Calculate net input"""
net_input(m::AbstractModel, x::AbstractVector) = x'*m.w + m.b
net_input(m::AbstractModel, X::AbstractMatrix) = X * m.w .+ m.b

"""AbstractModel batch prediction"""
(m::AbstractModel)(X::AbstractMatrix) = [m(x) for x in eachrow(X)]


# Perceptron
mutable struct Perceptron <: AbstractModel
    # Parameters
    w::Vector{Float64}
    b::Float64
    losses::Vector{Float64}
    fitted::Bool

    # Hyper parameters
    η::Float64
    num_iter::Int
    random_state::Union{Nothing, Int64}
    optim_alg::Symbol
    batch_size::Int 
end

function Perceptron(; η=0.01, num_iter=100, random_state=nothing,
            optim_alg=:SGD, batch_size=32)
    if !(optim_alg ∈ [:SGD, :Batch, :MiniBatch])
        throw("""`optim_alg` should be in [:SGD, :Batch, :MiniBatch]""")
    else        
        return Perceptron(Float64[], 0.0, Float64[], false, η, num_iter, random_state, optim_alg, batch_size)
    end
end

# Model training
"""Perceptron training model"""
function (m::Perceptron)(X::Matrix, y::Vector)
    if m.random_state !== nothing
        Random.seed!(m.random_state)
    end
    empty!(m.losses)

    # Initialize weights
    m.w = randn(size(X, 2)) ./ 100

    if m.optim_alg == :SGD
        n = length(y)
        for _ ∈ ProgressBar(1:m.num_iter)
            error = 0
            for i in 1:n
                xi, yi = X[i, :], y[i]
                ŷ = m(xi)                
                ∇ = m.η * (yi - ŷ)
                m.w .+= ∇ * xi
                m.b += ∇
                error += Int(∇ != 0.0)
            end
            push!(m.losses, error)
        end
        m.fitted = true
    elseif m.optim_alg == :Batch
        # Implement batch gradient descent
    elseif m.optim_alg == :MiniBatch
        # Implement mini-batch gradient descent
    end
end

"""Perceptron prediction with single observation"""
(m::Perceptron)(x::AbstractVector) = net_input(m, x) ≥ 0.0 ? 1 : 0

# ADALINE
"""Adaline training model"""
mutable struct Adaline <: AbstractModel
    # Parameters
    w::Vector{Float64}
    b::Float64
    losses::Vector{Float64}
    fitted::Bool

    # Hyper parameters
    η::Float64
    num_iter::Int
    random_state::Union{Nothing, Int64}
    optim_alg::Symbol
    batch_size::Int
    w_init::Bool
    shuffle::Bool
end

function Adaline(; η=0.01, num_iter=100, random_state=nothing,
            optim_alg=:SGD, batch_size=32, shuffle=true)
    if !(optim_alg ∈ [:SGD, :Batch, :MiniBatch])
        throw("""`optim_alg` should be in [:SGD, :Batch, :MiniBatch]""")
    else        
        return Adaline(Float64[], 0.0, Float64[], false, η, num_iter, random_state, optim_alg, batch_size, false, shuffle)
    end
end

"""Adaline prediction with single observation"""
(m::Adaline)(x::AbstractVector) = linearactivation(net_input(m, x)) ≥ 0.5 ? 1 : 0

function (m::Adaline)(X::Matrix, y::Vector; partial=false)
    if m.optim_alg == :SGD
        if partial == true
            # partial fit code will come here
        else
            if m.random_state !== nothing
               Random.seed!(m.random_state) 
            end
            m.w = randn(size(X,2)) ./ 100
            m.w_init = true
            empty!(m.losses)
            for _ ∈ 1:m.num_iter
                if m.shuffle
                    idx = randperm(length(y))
                    X, y = X[idx, :], y[idx]
                end
                losses = []
                for i ∈ 1:size(X, 1)
                    ŷ = linearactivation(net_input(m, X[i, :]))
                    error = (y[i] - ŷ)
                    m.w .+= m.η * 2.0 .* X[i, :] .* error
                    m.b += m.η * 2.0 *error
                    loss = error^2
                    push!(losses, loss)
                end
                avg_loss = mean(losses)
                push!(m.losses, avg_loss)
            end
        end
    elseif m.optim_alg == :Batch
        if m.random_state !== nothing
            Random.seed!(m.random_state)
        end
        empty!(m.losses)
    
        # Initialize weights
        m.w = randn(size(X, 2)) ./ 100

        n = length(y)
        for i ∈ ProgressBar(1:m.num_iter)
            ŷ = linearactivation(net_input(m, X))
            errors = (y .- ŷ)
            m.w .+= m.η .* 2.0 .* X'*errors ./ n
            m.b += m.η * 2.0 * mean(errors)
            loss = mean(errors.^2)
            push!(m.losses, loss)
        end
    elseif m.optim_alg == :MiniBatch
        # MiniBatch algorithm will come here 
    end
end


end # of module LinearModel