"""
    PDDL.Sets

Extends PDDL with set-valued fluents. Set members must be PDDL objects.
Register by calling `PDDL.Sets.register!`. Attach to a specific `domain`
by calling `PDDL.Set.attach!(domain)`.
"""
module Sets

using ..PDDL
using ..PDDL: Signature

construct_set(xs...) = Set{Symbol}(xs)
empty_set() = Set{Symbol}()
cardinality(s::Set) = length(s)
member(s::Set, x) = in(x, s)
subset(x::Set, y::Set) = issubset(x, y)
union(x::Set, y::Set) = Base.union(x, y)
intersect(x::Set, y::Set) = Base.intersect(x, y)
difference(x::Set, y::Set) = setdiff(x, y)
add_element(s::Set, x) = push!(copy(s), x)
rem_element(s::Set, x) = pop!(copy(s), x)

function register!()
    PDDL.register!(:datatype, "set", Set{Symbol})
    PDDL.register!(:function, "construct-set", construct_set)
    PDDL.register!(:function, "empty-set", empty_set)
    PDDL.register!(:function, "cardinality", cardinality)
    PDDL.register!(:predicate, "member", member)
    PDDL.register!(:predicate, "subset", subset)
    PDDL.register!(:function, "union", union)
    PDDL.register!(:function, "intersect", intersect)
    PDDL.register!(:function, "difference", difference)
    PDDL.register!(:function, "add-element", add_element)
    PDDL.register!(:function, "rem-element", rem_element)
    return nothing
end

function deregister!()
    PDDL.deregister!(:datatype, "set")
    PDDL.deregister!(:function, "construct-set")
    PDDL.deregister!(:function, "empty-set")
    PDDL.deregister!(:function, "cardinality")
    PDDL.deregister!(:predicate, "member")
    PDDL.deregister!(:predicate, "subset")
    PDDL.deregister!(:function, "union")
    PDDL.deregister!(:function, "intersect")
    PDDL.deregister!(:function, "difference")
    PDDL.deregister!(:function, "add-element")
    PDDL.deregister!(:function, "rem-element")
    return nothing
end

function attach!(domain::GenericDomain)
    PDDL.attach!(domain, :datatype, "set", Set{Symbol})
    PDDL.attach!(domain, :function, "construct-set", construct_set)
    PDDL.attach!(domain, :function, "empty-set", empty_set)
    PDDL.attach!(domain, :function, "cardinality", cardinality)
    PDDL.attach!(domain, :function, "member", member)
    PDDL.attach!(domain, :function, "subset", subset)
    PDDL.attach!(domain, :function, "union", union)
    PDDL.attach!(domain, :function, "intersect", intersect)
    PDDL.attach!(domain, :function, "difference", difference)
    PDDL.attach!(domain, :function, "add-element", add_element)
    PDDL.attach!(domain, :function, "rem-element", rem_element)
    return nothing
end


end
