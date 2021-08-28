"""
    Both

Type whose singleton instance `both` represents both `false` and `true`.
"""
struct Both end

"""
    both

Singleton value of type `Both` representing both `false` and `true`.
"""
const both = Both()

"""
    BooleanAbs

Belnap logic abstraction for Boolean values.
"""
const BooleanAbs = Union{Missing,Bool,Both}

lub(a::Both, b::Both) = both
lub(a::Both, b::Bool) = both
lub(a::Bool, b::Bool) = a === b ? a : both
lub(a::Both, b::Missing) = both
lub(a::Bool, b::Missing) = a
lub(a::BooleanAbs, b::BooleanAbs) = lub(b, a)

glb(a::Both, b::Both) = both
glb(a::Both, b::Bool) = b
glb(a::Bool, b::Bool) = a === b ? a : missing
glb(a::Both, b::Missing) = missing
glb(a::Bool, b::Missing) = missing
glb(a::BooleanAbs, b::BooleanAbs) = glb(b, a)

widen(a::BooleanAbs, b::BooleanAbs) = lub(a, b)

Base.:(!)(::Both) = both

Base.:(&)(a::Both, b::Both) = both
Base.:(&)(a::Both, b::Missing) = false
Base.:(&)(a::Both, b::Bool) = b ? both : false
Base.:(&)(a::BooleanAbs, b::Both) = b & a

Base.:(|)(a::Both, b::Both) = both
Base.:(|)(a::Both, b::Missing) = true
Base.:(|)(a::Both, b::Bool) = b ? true : both
Base.:(|)(a::BooleanAbs, b::Both) = b | a
