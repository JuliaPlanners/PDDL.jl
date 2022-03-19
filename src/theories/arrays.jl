"""
    PDDL.Arrays

Extends PDDL with array-valued fluents. Register by calling `PDDL.Arrays.@register()`.
Attach to a specific `domain` by calling `PDDL.Arrays.attach!(domain)`.
"""
module Arrays

using ..PDDL
import ..PDDL: valterm

# Array constructors
new_array(val, dims...) = fill!(Array{Any}(undef, dims), val)
new_matrix(val, h, w) = fill!(Matrix{Any}(undef, h, w), val)
new_vector(val, n) = fill!(Vector{Any}(undef, n), val)
new_bit_array(val::Bool, dims...) = val ? trues(dims) : falses(dims)
new_bit_matrix(val::Bool, h, w) = val ? trues(h, w) : falses(h, w)
new_bit_vector(val::Bool, n) = val ? trues(n) : falses(n)
vec(xs...) = collect(Any, xs)
bit_vec(xs...) = BitVector(collect(xs))
mat(vs::Vector{Any}...) = Matrix{Any}(hcat(vs...))
bit_mat(vs::BitVector...) = hcat(vs...)::BitMatrix
# Array accessors
get_index(a::AbstractArray{T,N}, idxs::Vararg{Int,N}) where {T,N} =
    getindex(a, idxs...)
set_index(a::AbstractArray{T,N}, val, idxs::Vararg{Int,N}) where {T,N} =
    setindex!(copy(a), val, idxs...)
# Array dimensions
length(a::AbstractArray) = Base.length(a)
height(m::AbstractMatrix) = size(m, 1)
width(m::AbstractMatrix) = size(m, 2)
ndims(a::AbstractArray) = Base.ndims(a)
# Push and pop
push(v::AbstractVector, x) = push!(copy(v), x)
pop(v::AbstractVector) = (v = copy(v); pop!(v); v)
# Transformations
_transpose(v::AbstractVector) = permutedims(v)
_transpose(m::AbstractMatrix) = permutedims(m)

valterm(v::AbstractVector) = Compound(:vec, Const.(v))
valterm(v::BitVector) = Compound(Symbol("bit-vec"), Const.(Int.(v)))
valterm(m::AbstractMatrix) =
    Compound(:transpose, [Compound(:mat, valterm.(eachrow(m)))])
valterm(m::BitMatrix) =
    Compound(:transpose,
        [Compound(Symbol("bit-mat"), valterm.(BitVector.(eachrow(m))))])

const DATATYPES = Dict(
    "array" => (type=Array{Any}, default=Array{Any}(undef, ())),
    "vector" => (type=Vector{Any}, default=Vector{Any}(undef, 0)),
    "matrix" => (type=Matrix{Any}, default=Matrix{Any}(undef, 0, 0)),
    "bit-array" => (type=BitArray, default=falses()),
    "bit-vector" => (type=BitVector, default=falses(0)),
    "bit-matrix" => (type=BitMatrix, default=falses(0, 0))
)

const PREDICATES = Dict()

const FUNCTIONS = Dict(
    # Array constructors
    "new-array" => new_array,
    "new-vector" => new_vector,
    "new-matrix" => new_matrix,
    "new-bit-array" => new_bit_array,
    "new-bit-vector" => new_bit_vector,
    "new-bit-matrix" => new_bit_matrix,
    "vec" => vec,
    "bit-vec" => bit_vec,
    "mat" => mat,
    "bit-mat" => bit_mat,
    # Array accessors
    "get-index" => get_index,
    "set-index" => set_index,
    # Array dimensions
    "length" => length,
    "height" => height,
    "width" => width,
    "ndims" => ndims,
    # Push and pop
    "push" => push,
    "pop" => pop,
    # Transformations
    "transpose" => _transpose
)

macro register()
    return PDDL.register_theory_expr(@__MODULE__)
end

function register!()
    return PDDL.register_theory!(@__MODULE__)
end

function deregister!()
    return PDDL.deregister_theory!(@__MODULE__)
end

function attach!(domain::Domain)
    return PDDL.attach_theory!(domain, @__MODULE__)
end

end
