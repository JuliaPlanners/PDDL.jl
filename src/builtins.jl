# Built in operators, functions, and effects

"""
    equiv(a, b)

Equivalence in concrete and abstract domains. Defaults to `a == b`.
"""
equiv(a, b) = a == b

"""
    nequiv(a, b)

Non-equivalence in concrete and abstract domains. Defaults to `a != b`.
"""
nequiv(a, b) = a != b

"Mapping from PDDL comparison operators to Julia functions."
const GLOBAL_PREDICATES = Dict{Symbol,Function}(
    op => eval(op) for op in [:<=, :>=, :<, :>]
)
GLOBAL_PREDICATES[:(==)] = equiv
GLOBAL_PREDICATES[:(!=)] = nequiv

"Mapping from PDDL evaluation operators to Julia functions."
const GLOBAL_FUNCTIONS = Dict{Symbol,Function}(
    op => eval(op) for op in [:+, :-, :*, :/]
)
merge!(GLOBAL_FUNCTIONS, GLOBAL_PREDICATES)

"Mapping from PDDL modifiers (i.e. in-place assignments) to Julia functions."
const GLOBAL_MODIFIERS = Dict{Symbol,Function}(
    :increase => +,
    :decrease => -,
    Symbol("scale-up") => *,
    Symbol("scale-down") => /
)
