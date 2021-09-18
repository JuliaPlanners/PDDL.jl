# Built in operators, functions, and effects

"Mapping from PDDL data types to Julia types."
const GLOBAL_DATATYPES = Dict{Symbol,Type}(
    :boolean => Bool,
    :integer => Int,
    :numeric => Float64,
)

"Mapping from PDDL comparison operators to Julia functions."
const GLOBAL_PREDICATES = Dict{Symbol,Function}(
    op => eval(op) for op in [:<=, :>=, :<, :>]
)

"Mapping from PDDL evaluation operators to Julia functions."
const GLOBAL_FUNCTIONS = Dict{Symbol,Function}(
    op => eval(op) for op in [:+, :-, :*, :/]
)

"Mapping from PDDL modifiers (i.e. in-place assignments) to Julia functions."
const GLOBAL_MODIFIERS = Dict{Symbol,Function}(
    :increase => +,
    :decrease => -,
    Symbol("scale-up") => *,
    Symbol("scale-down") => /
)

"""
    equiv(a, b)

Equivalence in concrete and abstract domains. Defaults to `a == b`.
"""
equiv(a, b) = a == b
GLOBAL_PREDICATES[:(==)] = equiv

"""
    nequiv(a, b)

Non-equivalence in concrete and abstract domains. Defaults to `a != b`.
"""
nequiv(a, b) = a != b
GLOBAL_PREDICATES[:(!=)] = nequiv

merge!(GLOBAL_FUNCTIONS, GLOBAL_PREDICATES)
