"""
    PDDL.Sets

Extends PDDL with set-valued fluents. Set members must be PDDL objects.
Register by calling `PDDL.Sets.@register()`. Attach to a specific `domain`
by calling `PDDL.Sets.attach!(domain)`.

# Datatypes

- `set`: A set of PDDL objects.

# Predicates

- `(member ?x - object ?s - set)`: Is `?x` a member of `?s`?
- `(subset ?s1 ?s2 - set)`: Is `?s1` a subset of `?s2`?

# Functions

- `(construct-set ?x ?y ... - object)`: Constructs a set from `?x`, `?y`, etc.
- `(empty-set)`: Constructs an empty set.
- `(cardinality ?s - set)`: The number of elements in `?s`.
- `(union ?s1 ?s2 - set)`: The union of `?s1` and `?s2`.
- `(intersect ?s1 ?s2 - set)`: The intersection of `?s1` and `?s2`.
- `(difference ?s1 ?s2 - set)`: The set difference of `?s1` and `?s2`.
- `(add-element ?s - set? ?x - object)`: Add `?x` to `?s`.
- `(rem-element ?s - set? ?x - object)`: Remove `?x` from `?s`.

"""
@pddltheory module Sets

using ..PDDL
using ..PDDL: SetAbs

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

set_to_term(s::Set) = isempty(s) ? Const(Symbol("(empty-set)")) :
    Compound(Symbol("construct-set"), PDDL.val_to_term.(collect(s)))

const DATATYPES = Dict(
    "set" => (type=Set{Symbol}, default=Set{Symbol}())
)

const ABSTRACTIONS = Dict(
    "set" => SetAbs{Set{Symbol}}
)

const CONVERTERS = Dict(
    "set" => set_to_term
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

end
