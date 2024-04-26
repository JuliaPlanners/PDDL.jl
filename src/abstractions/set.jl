"""
    SetAbs(xs...)

Set abstraction for arbitrary objects.
"""
struct SetAbs{T}
    set::Set{T}
    SetAbs{T}(; iter=(), set::Set{T} = Set{T}(iter)) where {T} = new(set)
end

function SetAbs{T}(x::T, xs::T...) where {T}
    y = SetAbs{T}()
    push!(y.set, x)
    for x in xs
        push!(y.set, x)
    end
    return y
end

SetAbs(xs::T...) where {T} = SetAbs{T}(xs...)

SetAbs(xs...) = SetAbs{Any}(xs...)

SetAbs(; set::Set{T}=Set{T}()) where {T} = SetAbs{T}(set=set)

Base.copy(x::SetAbs{T}) where {T} = SetAbs{T}(set=copy(x.set))

Base.convert(S::Type{SetAbs{T}}, x::T) where {T} = S(x)

Base.show(io::IO, x::SetAbs{T}) where {T} =
    print(io, "SetAbs", "(", join(x.set, ", "), ")")

Base.hash(x::SetAbs, h::UInt) = hash(x.set, h)

lub(a::SetAbs{T}, b::SetAbs{T}) where {T} = SetAbs{T}(; set=(a.set ∪ b.set))

function lub(S::Type{SetAbs{T}}, iter) where {T}
    val = SetAbs{T}()
    for x in iter
        union!(val.set, x)
    end
    return val
end

glb(a::SetAbs{T}, b::SetAbs{T}) where {T} = SetAbs{T}(; set=(a.set ∩ b.set))

function glb(S::Type{SetAbs{T}}, iter) where {T}
    val = SetAbs{T}()
    isfirst = true
    for x in iter
        if isfirst
            union!(val.set, x)
            isfirst = false
        else
            intersect!(val.set, x)
            isempty(val.set) && break
        end
    end
    return val
end

widen(a::SetAbs, b::SetAbs) = SetAbs(; set=(a.set ∪ b.set))

Base.:(==)(a::SetAbs, b::SetAbs) = a.set == b.set

for f in (:+, :-, :inv)
    @eval Base.$f(a::SetAbs) = SetAbs(set=Set(($f(x) for x in a.set)))
end    

for f in (:+, :-, :*, :/)
    @eval Base.$f(a::SetAbs, b::SetAbs) = 
        SetAbs(set=Set(($f(x, y) for x in a.set, y in b.set)))
    @eval Base.$f(a::SetAbs, b::Real) =
        SetAbs(set=Set(($f(x, b) for x in a.set)))
    @eval Base.$f(a::Real, b::SetAbs) =
        SetAbs(set=Set(($f(a, y) for y in b.set)))
end

uniquely_equal(a::SetAbs, b::SetAbs) =
    (length(a.set) == length(b.set) == 1) && first(a.set) == first(b.set)

equiv(a::SetAbs, b::SetAbs) = 
    isdisjoint(a.set, b.set) ? false : (uniquely_equal(a, b) ? true : both)
nequiv(a::SetAbs, b::SetAbs) =
    isdisjoint(a.set, b.set) ? true : (uniquely_equal(a, b) ? false : both)

Base.:<(a::SetAbs, b::SetAbs) =
    lub(BooleanAbs, (x < y for x in a.set, y in b.set))
Base.:<=(a::SetAbs, b::SetAbs) =
    lub(BooleanAbs, (x <= y for x in a.set, y in b.set))

equiv(a::SetAbs{T}, b::T) where {T} =
    b in a.set ? (length(a.set) == 1 ? true : both) : false
nequiv(a::SetAbs{T}, b::T) where {T} =
    b in a.set ? (length(a.set) == 1 ? false : both) : true
Base.:<(a::SetAbs, b::Real) =
    lub(BooleanAbs, (x < b for x in a.set))
Base.:<=(a::SetAbs, b::Real) =
    lub(BooleanAbs, (x <= b for x in a.set))

equiv(a::T, b::SetAbs{T}) where {T} =
    a in b.set ? (length(b.set) == 1 ? true : both) : false
nequiv(a::T, b::SetAbs{T}) where {T} =
    a in b.set ? (length(b.set) == 1 ? false : both) : true
Base.:<(a::Real, b::SetAbs) =
    lub(BooleanAbs, (a < y for y in b.set))
Base.:<=(a::Real, b::SetAbs) =
    lub(BooleanAbs, (a <= y for y in b.set))
