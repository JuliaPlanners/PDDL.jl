"""
    IntervalAbs(lo::Real, hi::Real)

Interval abstraction for real-valued numbers.
"""
struct IntervalAbs{T <: Real}
    lo::T
    hi::T
    function IntervalAbs{T}(lo::T, hi::T) where {T <: Real}
        lo > hi ? new{T}(typemax(T), typemin(T)) : new{T}(lo, hi)
    end
end

IntervalAbs{T}(x::Real) where {T} =
    IntervalAbs{T}(x, x)
IntervalAbs(x::T) where {T <: Real} =
    IntervalAbs{T}(x, x)
IntervalAbs{T}(lo::Real, hi::Real) where {T} =
    IntervalAbs{T}(convert(T, lo), convert(T, hi))
IntervalAbs(lo::T, hi::U) where {T <: Real, U <: Real} =
    IntervalAbs{promote_type(T, U)}(lo, hi)

empty_interval(I::Type{IntervalAbs{T}}) where {T <: Real} =
    I(typemax(T), typemin(T))
empty_interval(x::IntervalAbs) =
    empty_interval(typeof(x))

Base.copy(x::IntervalAbs) = x

Base.convert(I::Type{IntervalAbs{T}}, x::Real) where {T <: Real} = I(x)

Base.show(io::IO, x::IntervalAbs) = print(io, "[$(x.lo), $(x.hi)]")

Base.hash(x::IntervalAbs, h::UInt) = hash(x.lo, hash(x.hi, h))

lub(a::IntervalAbs, b::IntervalAbs) = a ∪ b
glb(a::IntervalAbs, b::IntervalAbs) = a ∩ b

widen(a::IntervalAbs, b::IntervalAbs) = a ∪ b

Base.:(==)(a::IntervalAbs, b::IntervalAbs) =
    a.lo == b.lo && a.hi == b.hi
Base.isapprox(a::IntervalAbs, b::IntervalAbs; kwargs...) =
    isapprox(a.lo, b.lo; kwargs...) && isapprox(a.hi, b.hi; kwargs...)

Base.:+(a::IntervalAbs) = a
Base.:-(a::IntervalAbs) = IntervalAbs(-a.hi, -a.lo)

function Base.:+(a::IntervalAbs, b::IntervalAbs)
    return IntervalAbs(a.lo + b.lo, a.hi + b.hi)
end

function Base.:-(a::IntervalAbs, b::IntervalAbs)
    return IntervalAbs(a.lo - b.hi, a.hi - b.lo)
end

function Base.:*(a::IntervalAbs, b::IntervalAbs)
    lo = min(a.lo * b.lo, a.lo * b.hi, a.hi * b.lo, a.hi * b.hi)
    hi = max(a.lo * b.lo, a.lo * b.hi, a.hi * b.lo, a.hi * b.hi)
    return IntervalAbs(lo, hi)
end

function Base.:/(a::IntervalAbs, b::IntervalAbs)
    a * inv(b)
end

function Base.inv(a::IntervalAbs{T}) where {T}
    if a.lo == 0 && a.hi == 0
        if T <: Integer
            throw(DivideError())
        elseif signbit(a.lo) != signbit(a.hi)
            return IntervalAbs{T}(T(-Inf), T(Inf))
        else
            return IntervalAbs{T}(T(copysign(Inf, a.lo)))
        end
    elseif a.lo < 0 && a.hi > 0
        T <: Integer ? throw(DivideError()) : return IntervalAbs(-Inf, Inf)
    elseif a.lo == 0
        return IntervalAbs(1 / a.hi, Inf)
    elseif a.hi == 0
        return IntervalAbs(-Inf, 1 / a.lo)
    else
        return IntervalAbs(1 / a.hi, 1 / a.lo)
    end
end

Base.:+(a::IntervalAbs, b::Real) =
    IntervalAbs(a.lo + b, a.hi + b)
Base.:-(a::IntervalAbs, b::Real) =
    IntervalAbs(a.lo - b, a.hi - b)
Base.:*(a::IntervalAbs, b::Real) =
    signbit(b) ? IntervalAbs(a.hi*b, a.lo*b) : IntervalAbs(a.lo*b, a.hi*b)
Base.:/(a::IntervalAbs, b::Real) =
    signbit(b) ? IntervalAbs(a.hi/b, a.lo/b) : IntervalAbs(a.lo/b, a.hi/b)

Base.:+(a::Real, b::IntervalAbs) = b + a
Base.:-(a::Real, b::IntervalAbs) = -b + a
Base.:*(a::Real, b::IntervalAbs) = b * a
Base.:/(a::Real, b::IntervalAbs) = inv(b) * a

function Base.union(a::IntervalAbs, b::IntervalAbs)
    IntervalAbs(min(a.lo, b.lo), max(a.hi, b.hi))
end

function Base.intersect(a::IntervalAbs{T}, b::IntervalAbs{U}) where {T, U}
    if a.lo > b.hi || a.hi < b.lo
        return empty_interval(promote_type{T, U})
    else
        return IntervalAbs(max(a.lo, b.lo), min(a.hi, b.hi))
    end
end

Base.issubset(a::IntervalAbs, b::IntervalAbs) =
    a.lo >= b.lo && a.hi <= b.hi
Base.in(a::Real, b::IntervalAbs) =
    a >= b.lo && a <= b.hi

equiv(a::IntervalAbs, b::IntervalAbs) = !(a.lo > b.hi || a.hi < b.lo)
nequiv(a::IntervalAbs, b::IntervalAbs) = a.lo > b.hi || a.hi < b.lo
Base.:<(a::IntervalAbs, b::IntervalAbs) = a.lo < b.hi
Base.:<=(a::IntervalAbs, b::IntervalAbs) = a.lo <= b.hi

equiv(a::IntervalAbs, b::Real) = b in a
nequiv(a::IntervalAbs, b::Real) = !(a.lo == a.hi == b)
Base.:<(a::IntervalAbs, b::Real) = a.lo < b
Base.:<=(a::IntervalAbs, b::Real) = a.lo <= b

equiv(a::Real, b::IntervalAbs) = a in b
nequiv(a::Real, b::IntervalAbs) = !(a == b.lo == b.hi)
Base.:<(a::Real, b::IntervalAbs) = a < b.hi
Base.:<=(a::Real, b::IntervalAbs) = a <= b.hi
