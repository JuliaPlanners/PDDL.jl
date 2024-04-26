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

Base.copy(::Both) = both
Base.show(io::IO, ::Both) = print(io, "both")

isboth(b::Both) = true
isboth(b) = false

"""
    BooleanAbs

Belnap logic abstraction for Boolean values.
"""
const BooleanAbs = Union{Missing,Bool,Both}

BooleanAbs(x::BooleanAbs) = x

lub(a::Both, b::Both) = both
lub(a::Both, b::Bool) = both
lub(a::Bool, b::Bool) = a === b ? a : both
lub(a::Both, b::Missing) = both
lub(a::Bool, b::Missing) = a
lub(a::BooleanAbs, b::BooleanAbs) = lub(b, a)

function lub(::Type{BooleanAbs}, iter)
    val::BooleanAbs = missing
    for x in iter
        val = lub(val, x)
        isboth(val) && return val
    end
    return val
end

glb(a::Both, b::Both) = both
glb(a::Both, b::Bool) = b
glb(a::Bool, b::Bool) = a === b ? a : missing
glb(a::Both, b::Missing) = missing
glb(a::Bool, b::Missing) = missing
glb(a::BooleanAbs, b::BooleanAbs) = glb(b, a)

function glb(::Type{BooleanAbs}, iter)
    val::BooleanAbs = both
    for x in iter
        val = glb(val, x)
        ismissing(val) && return val
    end
    return val
end

widen(a::BooleanAbs, b::BooleanAbs) = lub(a, b)

equiv(a::Both, b::Bool) = true
equiv(a::Bool, b::Both) = true

Base.:(!)(::Both) = both

Base.:(&)(a::Both, b::Both) = both
Base.:(&)(a::Both, b::Missing) = missing
Base.:(&)(a::Both, b::Bool) = b ? both : false
Base.:(&)(a::BooleanAbs, b::Both) = b & a

Base.:(|)(a::Both, b::Both) = both
Base.:(|)(a::Both, b::Missing) = missing
Base.:(|)(a::Both, b::Bool) = b ? true : both
Base.:(|)(a::BooleanAbs, b::Both) = b | a

"Four-valued logical version of `Base.any`."
function any4(itr)
    anymissing = false
    anyboth = false
    for x in itr
        if ismissing(x)
            anymissing = true
        elseif isboth(x)
            anyboth = true
        elseif x
            return true
        end
    end
    return anymissing ? missing : anyboth ? both : false
end

"Four-valued logical version of `Base.all`."
function all4(itr)
    anymissing = false
    anyboth = false
    for x in itr
        if ismissing(x)
            anymissing = true
        elseif isboth(x)
            anyboth = true
        elseif x
            continue
        else
            return false
        end
    end
    return anymissing ? missing : anyboth ? both : true
end

# Teach GenericState the way of true contradictions
function set_fluent!(state::GenericState, val::Both, term::Const)
    push!(state.facts, term, negate(term))
    return val
end

function set_fluent!(state::GenericState, val::Both, term::Compound)
    push!(state.facts, term, negate(term))
    return val
end
