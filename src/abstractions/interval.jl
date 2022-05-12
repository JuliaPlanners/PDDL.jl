import IntervalArithmetic

"""
    IntervalAbs(lo::Real, hi::Real)

Interval abstraction for real-valued numbers.
"""
struct IntervalAbs{T <: Real}
    interval::IntervalArithmetic.Interval{T}
end

IntervalAbs{T}(x::Integer) where {T <: Integer} =
    IntervalAbs{T}(T(x), T(x)+1)
IntervalAbs{T}(x::Union{AbstractFloat,Integer}) where {T <:AbstractFloat} =
    IntervalAbs{T}(T(x), T(x))
IntervalAbs{T}(a::T, b::T) where {T <: Real} =
    IntervalAbs{T}(IntervalArithmetic.Interval{T}(a, b))

Base.copy(x::IntervalAbs) = x

Base.convert(I::Type{IntervalAbs{T}}, x::Real) where {T <: Real} = I(x)

Base.show(io::IO, x::IntervalAbs) = Base.show(io, x.interval)

lub(a::IntervalAbs, b::IntervalAbs) = IntervalAbs(a.interval ∪ b.interval)
glb(a::IntervalAbs, b::IntervalAbs) = IntervalAbs(a.interval ∩ b.interval)

widen(a::IntervalAbs, b::IntervalAbs) = IntervalAbs(a.interval ∪ b.interval)

Base.:(==)(a::IntervalAbs, b::IntervalAbs) = a.interval == b.interval

Base.:+(a::IntervalAbs) = a
Base.:-(a::IntervalAbs) = IntervalAbs(-a)

Base.:+(a::IntervalAbs, b::IntervalAbs) = IntervalAbs(a.interval + b.interval)
Base.:-(a::IntervalAbs, b::IntervalAbs) = IntervalAbs(a.interval - b.interval)
Base.:*(a::IntervalAbs, b::IntervalAbs) = IntervalAbs(a.interval * b.interval)
Base.:/(a::IntervalAbs, b::IntervalAbs) = IntervalAbs(a.interval / b.interval)

Base.:+(a::IntervalAbs, b::Real) = IntervalAbs(a.interval + b)
Base.:-(a::IntervalAbs, b::Real) = IntervalAbs(a.interval - b)
Base.:*(a::IntervalAbs, b::Real) = IntervalAbs(a.interval * b)
Base.:/(a::IntervalAbs, b::Real) = IntervalAbs(a.interval / b)

Base.:+(a::Real, b::IntervalAbs) = IntervalAbs(a + b.interval)
Base.:-(a::Real, b::IntervalAbs) = IntervalAbs(a - b.interval)
Base.:*(a::Real, b::IntervalAbs) = IntervalAbs(a * b.interval)
Base.:/(a::Real, b::IntervalAbs) = IntervalAbs(a / b.interval)

equiv(a::IntervalAbs, b::IntervalAbs) =
    !isdisjoint(a.interval, b.interval)
nequiv(a::IntervalAbs, b::IntervalAbs) =
    isdisjoint(a.interval, b.interval)
Base.:<(a::IntervalAbs, b::IntervalAbs) =
    !IntervalArithmetic.precedes(b.interval, a.interval)
Base.:<=(a::IntervalAbs, b::IntervalAbs) =
    !IntervalArithmetic.strictprecedes(b.interval, a.interval)

equiv(a::IntervalAbs, b::Real) = b ⊆ a.interval
nequiv(a::IntervalAbs, b::Real) = !(a.interval.lo == a.interval.hi == b)
Base.:<(a::IntervalAbs, b::Real) = a.interval.lo < b
Base.:<=(a::IntervalAbs, b::Real) = a.interval.lo <= b

equiv(a::Real, b::IntervalAbs) = a ⊆ b.interval
nequiv(a::Real, b::IntervalAbs) = !(a == b.interval.lo == b.interval.hi)
Base.:<(a::Real, b::IntervalAbs) = a < b.interval.hi
Base.:<=(a::Real, b::IntervalAbs) = a <= b.interval.hi
