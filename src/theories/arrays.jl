"""
    PDDL.Arrays

Extends PDDL with array-valued fluents. Register by calling `PDDL.Arrays.@register()`.
Attach to a specific `domain` by calling `PDDL.Arrays.attach!(domain)`.
"""
@pddltheory module Arrays

using ..PDDL

# Generic array constructors
new_array(val, dims...) = fill!(Array{Any}(undef, dims), val)
new_matrix(val, h, w) = fill!(Matrix{Any}(undef, h, w), val)
new_vector(val, n) = fill!(Vector{Any}(undef, n), val)
vec(xs...) = collect(Any, xs)
mat(vs::Vector{Any}...) = Matrix{Any}(hcat(vs...))

# Bit array constructors
new_bit_array(val::Bool, dims...) = val ? trues(dims) : falses(dims)
new_bit_matrix(val::Bool, h, w) = val ? trues(h, w) : falses(h, w)
new_bit_vector(val::Bool, n) = val ? trues(n) : falses(n)
bit_vec(xs...) = BitVector(collect(xs))
bit_mat(vs::BitVector...) = hcat(vs...)::BitMatrix

# Integer array constructors
new_int_array(val::Integer, dims...) = fill!(Array{Int}(undef, dims), val)
new_int_matrix(val::Integer, h, w) = fill!(Matrix{Int}(undef, h, w), val)
new_int_vector(val::Integer, n) = fill!(Vector{Int}(undef, n), val)
int_vec(xs...) = collect(Int, xs)
int_mat(vs::Vector{Int}...) = Matrix{Int}(hcat(vs...))

# Numeric array constructors
new_num_array(val::Real, dims...) = fill!(Array{Float64}(undef, dims), val)
new_num_matrix(val::Real, h, w) = fill!(Matrix{Float64}(undef, h, w), val)
new_num_vector(val::Real, n) = fill!(Vector{Float64}(undef, n), val)
num_vec(xs...) = collect(Float64, xs)
num_mat(vs::Vector{Float64}...) = Matrix{Float64}(hcat(vs...))

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

# Conversions to terms
vec_to_term(v::AbstractVector) =
    Compound(:vec, PDDL.val_to_term.(v))
bitvec_to_term(v::BitVector) =
    Compound(Symbol("bit-vec"), Const.(Int.(v)))
intvec_to_term(v::Vector{<:Integer}) =
    Compound(Symbol("int-vec"), Const.(Int.(v)))
numvec_to_term(v::Vector{<:Real}) =
    Compound(Symbol("num-vec"), Const.(Float64.(v)))

mat_to_term(m::AbstractMatrix) =
    Compound(:transpose, [Compound(:mat, vec_to_term.(eachrow(m)))])
bitmat_to_term(m::BitMatrix) =
    Compound(:transpose, [Compound(Symbol("bit-mat"), bitvec_to_term.(BitVector.(eachrow(m))))])
intmat_to_term(m::Matrix{<:Integer}) =
    Compound(:transpose, [Compound(Symbol("int-mat"), intvec_to_term.(eachrow(m)))])
nummat_to_term(m::Matrix{<:Real}) =
    Compound(:transpose, [Compound(Symbol("num-mat"), numvec_to_term.(eachrow(m)))])

const DATATYPES = Dict(
    "array" => (type=Array{Any}, default=Array{Any}(undef, ())),
    "vector" => (type=Vector{Any}, default=Vector{Any}(undef, 0)),
    "matrix" => (type=Matrix{Any}, default=Matrix{Any}(undef, 0, 0)),
    "bit-array" => (type=BitArray, default=falses()),
    "bit-vector" => (type=BitVector, default=falses(0)),
    "bit-matrix" => (type=BitMatrix, default=falses(0, 0)),
    "int-array" => (type=Array{Int64}, default=zeros(Int64)),
    "int-vector" => (type=Vector{Int64}, default=zeros(Int64, 0)),
    "int-matrix" => (type=Matrix{Int64}, default=zeros(Int64, 0, 0)),
    "num-array" => (type=Array{Float64}, default=zeros(Float64)),
    "num-vector" => (type=Vector{Float64}, default=zeros(Float64, 0)),
    "num-matrix" => (type=Matrix{Float64}, default=zeros(Float64, 0, 0)),
)

const CONVERTERS = Dict(
    "vector" => vec_to_term,
    "matrix" => mat_to_term,
    "bit-vector" => bitvec_to_term,
    "bit-matrix" => bitmat_to_term,
    "int-vector" => intvec_to_term,
    "int-matrix" => intmat_to_term,
    "num-vector" => numvec_to_term,
    "num-matrix" => nummat_to_term
)

const PREDICATES = Dict()

const FUNCTIONS = Dict(
    # Generic array constructors
    "new-array" => new_array,
    "new-vector" => new_vector,
    "new-matrix" => new_matrix,
    "vec" => vec,
    "mat" => mat,
    # Bit array constructors
    "new-bit-array" => new_bit_array,
    "new-bit-vector" => new_bit_vector,
    "new-bit-matrix" => new_bit_matrix,
    "bit-vec" => bit_vec,
    "bit-mat" => bit_mat,
    # Integer array constructors
    "new-int-array" => new_int_array,
    "new-int-vector" => new_int_vector,
    "new-int-matrix" => new_int_matrix,
    "int-vec" => int_vec,
    "int-mat" => int_mat,
    # Numeric array constructors
    "new-num-array" => new_num_array,
    "new-num-vector" => new_num_vector,
    "new-num-matrix" => new_num_matrix,
    "num-vec" => num_vec,
    "num-mat" => num_mat,
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

end
