"""
    PDDL.Sets

Extends PDDL with set-valued fluents. Set members must be PDDL objects.
Register by calling `PDDL.Sets.@register()`. Attach to a specific `domain`
by calling `PDDL.Sets.attach!(domain)`.
"""
module Sets

using ..PDDL
import ..PDDL: valterm

construct_set(xs::Symbol...) = Set{Symbol}(xs)
empty_set() = Set{Symbol}()
cardinality(s::Set) = length(s)
member(s::Set, x) = in(x, s)
subset(x::Set, y::Set) = issubset(x, y)
union(x::Set, y::Set) = Base.union(x, y)
intersect(x::Set, y::Set) = Base.intersect(x, y)
difference(x::Set, y::Set) = setdiff(x, y)
add_element(s::Set, x) = push!(copy(s), x)
rem_element(s::Set, x) = pop!(copy(s), x)

valterm(s::Set) = isempty(s) ? Const(Symbol("(empty-set)")) :
    Compound(Symbol("construct-set"), valterm.(collect(s)))

const DATATYPES = Dict(
    "set" => (type=Set{Symbol}, default=Set{Symbol}())
)

const PREDICATES = Dict(
    "member" => member,
    "subset" => subset
)

const FUNCTIONS = Dict(
    "construct-set" => construct_set,
    "empty-set" => empty_set,
    "cardinality" => cardinality,
    "union" => union,
    "intersect" => intersect,
    "difference" => difference,
    "add-element" => add_element,
    "rem-element" => rem_element
)

macro register()
    expr = Expr(:block)
    for (name, ty) in DATATYPES
        e = :(PDDL.@register(:datatype, $(QuoteNode(name)), $(QuoteNode(ty))))
        push!(expr.args, e)
    end
    for (name, f) in PREDICATES
        e = :(PDDL.@register(:predicate, $(QuoteNode(name)), $(QuoteNode(f))))
        push!(expr.args, e)
    end
    for (name, f) in FUNCTIONS
        e = :(PDDL.@register(:function, $(QuoteNode(name)), $(QuoteNode(f))))
        push!(expr.args, e)
    end
    push!(expr.args, nothing)
    return expr
end

function register!()
    for (name, ty) in DATATYPES
        PDDL.register!(:datatype, name, ty)
    end
    for (name, f) in PREDICATES
        PDDL.register!(:predicate, name, f)
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
    for (name, f) in PREDICATES
        PDDL.deregister!(:predicate, name)
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
    for (name, f) in PREDICATES
        PDDL.attach!(domain, :function, name, f)
    end
    for (name, f) in FUNCTIONS
        PDDL.attach!(domain, :function, name, f)
    end
    return nothing
end

end
