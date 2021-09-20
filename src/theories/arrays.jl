"""
    PDDL.Arrays

Extends PDDL with array-valued fluents. Register by calling `PDDL.Arrays.register!`.
Attach to a specific `domain` by calling `PDDL.Arrays.attach!(domain)`.
"""
module Arrays

using ..PDDL
import ..PDDL: defaultval

# Array constructors
new_array(val, dims...) = fill!(Array{Any}(undef, dims), val)
new_matrix(val, h, w) = fill!(Matrix{Any}(undef, h, w), val)
new_vector(val, n) = fill!(Vector{Any}(undef, n), val)
new_bit_array(val::Bool, dims...) = val ? trues(dims) : falses(dims)
new_bit_matrix(val::Bool, h, w) = val ? trues(h, w) : falses(h, w)
new_bit_vector(val::Bool, n) = val ? trues(n) : falses(n)
vec(xs...) = Vector{Any}(xs)
bit_vec(xs::Bool...) = BitVector(xs)
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

defaultval(::Val{:array}) = Array{Any}(undef, ())
defaultval(::Val{:vector}) = Vector{Any}(undef, 0)
defaultval(::Val{:matrix}) = Matrix{Any}(undef, 0, 0)
defaultval(::Val{Symbol("bit-array")}) = falses()
defaultval(::Val{Symbol("bit-vector")}) = falses(0)
defaultval(::Val{Symbol("bit-matrix")}) = falses(0, 0)

const DATATYPES = Dict(
    "array" => Array{Any},
    "vector" => Vector{Any},
    "matrix" => Matrix{Any},
    "bit-array" => BitArray,
    "bit-vector" => BitVector,
    "bit-matrix" => BitMatrix
)

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
    "pop" => pop
)

function register!()
    for (name, ty) in DATATYPES
        PDDL.register!(:datatype, name, ty)
    end
    for (name, f) in FUNCTIONS
        PDDL.register!(:function, name, f)
    end
    return nothing
end

function deregister!()
    for (name, ty) in DATATYPES
        PDDL.deregister!(:datatype, name)
    end
    for (name, f) in FUNCTIONS
        PDDL.deregister!(:function, name)
    end
    return nothing
end

function attach!(domain::GenericDomain)
    for (name, ty) in DATATYPES
        PDDL.attach!(domain, :datatype, name, ty)
    end
    for (name, f) in FUNCTIONS
        PDDL.attach!(domain, :function, name, f)
    end
    return nothing
end

end
