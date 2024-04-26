"""
    PDDL.Arrays

Extends PDDL with array-valued fluents. Register by calling `PDDL.Arrays.@register()`.
Attach to a specific `domain` by calling `PDDL.Arrays.attach!(domain)`.
"""
@pddltheory module Arrays

using ..PDDL
using ..PDDL: BooleanAbs, IntervalAbs, SetAbs, lub, isboth, empty_interval

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

# Index constructors
index(idxs::Int...) = idxs
vec_index(i::Int) = i
mat_index(i::Int, j::Int) = (i, j)

# Array accessors
get_index(a::AbstractArray{T,N}, idxs::Vararg{Int,N}) where {T,N} =
    getindex(a, idxs...)
get_index(a::AbstractArray{T,N}, idxs::NTuple{N,Int}) where {T,N} =
    getindex(a, idxs...)
set_index(a::AbstractArray{T,N}, val, idxs::Vararg{Int,N}) where {T,N} =
    setindex!(copy(a), val, idxs...)
set_index(a::AbstractArray{T,N}, val, idxs::NTuple{N,Int}) where {T,N} =
    setindex!(copy(a), val, idxs...)

# Bounds checking
has_index(a::AbstractArray{T,N}, idxs::Vararg{Int,N}) where {T,N} =
    checkbounds(Bool, a, idxs...)
has_index(a::AbstractArray{T,N}, idxs::NTuple{N,Int}) where {T,N} =
    checkbounds(Bool, a, idxs...)
has_row(m::AbstractMatrix, i::Int) =
    checkbounds(Bool, m, i, :)
has_col(m::AbstractMatrix, j::Int) =
    checkbounds(Bool, m, :, j)

# Index component accessors
get_index(idx::NTuple{N, Int}, i::Int) where {N} =
    getindex(idx, i)
get_row(idx::Tuple{Int, Int}) = idx[1]
get_col(idx::Tuple{Int, Int}) = idx[2]
set_index(idx::NTuple{N, Int}, val::Int, i::Int) where {N} =
    (idx[1:i-1]..., val, idx[i+1:end]...)
set_row(idx::Tuple{Int, Int}, val::Int) = (val, idx[2])
set_col(idx::Tuple{Int, Int}, val::Int) = (idx[1], val)

# Index component modifiers
increase_index(idx::NTuple{N, Int}, i::Int, val::Int) where {N} =
    (idx[1:i-1]..., idx[i] + val, idx[i+1:end]...)
increase_row(idx::Tuple{Int, Int}, val::Int) = (idx[1] + val, idx[2])
increase_col(idx::Tuple{Int, Int}, val::Int) = (idx[1], idx[2] + val)
decrease_index(idx::NTuple{N, Int}, i::Int, val::Int) where {N} =
    (idx[1:i-1]..., idx[i] - val, idx[i+1:end]...)
decrease_row(idx::Tuple{Int, Int}, val::Int) = (idx[1] - val, idx[2])
decrease_col(idx::Tuple{Int, Int}, val::Int) = (idx[1], idx[2] - val)

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

# Accessors with abstract indices
function get_index(
    a::AbstractArray{T,N}, idxs::Vararg{SetAbs{Int},N}
) where {T,N}
    val = SetAbs{T}()
    for i in Iterators.product((i.set for i in idxs)...)
        has_index(a, i) && push!(val.set, get_index(a, i))
    end
    return val
end

function get_index(
    a::AbstractArray{T,N}, idxs::SetAbs{NTuple{N, Int}}
) where {T,N}
    val = SetAbs{T}()
    for i in idxs.set
        has_index(a, i) && push!(val.set, get_index(a, i))
    end
    return val
end

function get_index(
    a::AbstractArray{T,N}, idxs::SetAbs{NTuple{N, Int}}
) where {T <: BooleanAbs, N}
    val::BooleanAbs = missing
    for i in idxs.set
        has_index(a, i) || continue
        val = lub(val, get_index(a, i))
    end
    return val
end

function get_index(
    a::AbstractArray{T,N}, idxs::Vararg{IntervalAbs{Int},N}
) where {T <: Real,N}
    val = empty_interval(IntervalAbs{T})
    for i in Iterators.product((i.lo:i.hi for i in idxs)...)
        has_index(a, i) || continue
        val = lub(val, IntervalAbs{T}(get_index(a, i)))
    end
    return val
end

function get_index(
    a::AbstractArray{T,N}, idxs::Vararg{IntervalAbs{Int},N}
) where {T <: BooleanAbs,N}
    val::BooleanAbs = missing
    for i in Iterators.product((i.lo:i.hi for i in idxs)...)
        has_index(a, i) || continue
        val = lub(val, get_index(a, i))
    end
    return val
end

# Bounds checking with abstract indices
function has_index(
    a::AbstractArray{T,N}, idxs::Vararg{SetAbs{Int},N}
) where {T, N}
    iter = (has_index(a, i) for i in Iterators.product((i.set for i in idxs)...))
    return lub(BooleanAbs, iter)
end

function has_index(
    a::AbstractArray{T,N}, idxs::SetAbs{NTuple{N, Int}}
) where {T,N}
    iter = (has_index(a, i) for i in idxs.set)
    return lub(BooleanAbs, iter)
end

function has_index(
    a::AbstractArray{T,N}, idxs::Vararg{IntervalAbs{Int},N}
) where {T, N}
    iter = (has_index(a, i) for i in
            Iterators.product(((i.lo, i.hi) for i in idxs)...))
    return lub(BooleanAbs, iter)
end

has_row(m::AbstractMatrix, idxs::SetAbs{Int}) =
    lub(BooleanAbs, (has_row(m, i) for i in idxs.set))
has_row(m::AbstractMatrix, i::IntervalAbs{Int}) =
    lub(has_row(m, i.lo), has_row(m, i.hi))

has_col(m::AbstractMatrix, idxs::SetAbs{Int}) = 
    lub(BooleanAbs, (has_col(m, j) for j in idxs.set))
has_col(m::AbstractMatrix, j::IntervalAbs{Int}) =
    lub(has_col(m, j.lo), has_col(m, j.hi))

# Abstract index component accessors
get_index(idxs::SetAbs{T}, i::Int) where {T <: Tuple} =
    SetAbs{Int}(;iter=(idx[i] for idx in idxs.set))
get_row(idxs::SetAbs{T}) where {T <: Tuple} =
    SetAbs{Int}(;iter=(idx[1] for idx in idxs.set))
get_col(idxs::SetAbs{T}) where {T <: Tuple} =
    SetAbs{Int}(;iter=(idx[2] for idx in idxs.set))

set_index(idxs::SetAbs{T}, i::Int, val::Int) where {T <: Tuple} =
    SetAbs{T}(;iter=(set_index(idx, i, val) for idx in idxs.set))
set_row(idxs::SetAbs{T}, val::Int) where {T <: Tuple} =
    SetAbs{T}(;iter=(set_row(idx, val) for idx in idxs.set))
set_col(idxs::SetAbs{T}, val::Int) where {T <: Tuple} =
    SetAbs{T}(;iter=(set_col(idx, val) for idx in idxs.set))

# Abstract index component modifiers
increase_index(idxs::SetAbs{T}, i::Int, val::Int) where {T <: Tuple} =
    SetAbs{T}(;iter=(increase_index(idx, i, val) for idx in idxs.set))
increase_row(idxs::SetAbs{T}, val::Int) where {T <: Tuple} =
    SetAbs{T}(;iter=(increase_row(idx, val) for idx in idxs.set))
increase_col(idxs::SetAbs{T}, val::Int) where {T <: Tuple} =
    SetAbs{T}(;iter=(increase_col(idx, val) for idx in idxs.set))

decrease_index(idxs::SetAbs{T}, i::Int, val::Int) where {T <: Tuple} =
    SetAbs{T}(;iter=(decrease_index(idx, i, val) for idx in idxs.set))
decrease_row(idxs::SetAbs{T}, val::Int) where {T <: Tuple} =
    SetAbs{T}(;iter=(decrease_row(idx, val) for idx in idxs.set))
decrease_col(idxs::SetAbs{T}, val::Int) where {T <: Tuple} =
    SetAbs{T}(;iter=(decrease_col(idx, val) for idx in idxs.set))

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

index_to_term(idxs::NTuple{N,Int}) where {N} =
    Compound(:index, [Const(i) for i in idxs])

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
    "array-index" => (type=NTuple{N, Int} where {N}, default=()),
    "vector-index" => (type=Int, default=1),
    "matrix-index" => (type=Tuple{Int, Int}, default=(1, 1))
)

const CONVERTERS = Dict(
    "vector" => vec_to_term,
    "matrix" => mat_to_term,
    "bit-vector" => bitvec_to_term,
    "bit-matrix" => bitmat_to_term,
    "int-vector" => intvec_to_term,
    "int-matrix" => intmat_to_term,
    "num-vector" => numvec_to_term,
    "num-matrix" => nummat_to_term,
    "array-index" => index_to_term,
    "matrix-index" => index_to_term
)

const PREDICATES = Dict(
    # Bounds checking
    "has-index" => has_index,
    "has-row" => has_row,
    "has-col" => has_col
)

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
    # Array index constructors
    "index" => index,
    "vec-index" => vec_index,
    "mat-index" => mat_index,
    # Array accessors
    "get-index" => get_index,
    "set-index" => set_index,
    # Index accessors
    "get-row" => get_row,
    "get-col" => get_col,
    "set-row" => set_row,
    "set-col" => set_col,
    # Index modifiers
    "increase-index" => increase_index,
    "increase-row" => increase_row,
    "increase-col" => increase_col,
    "decrease-index" => decrease_index,
    "decrease-row" => decrease_row,
    "decrease-col" => decrease_col,
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
