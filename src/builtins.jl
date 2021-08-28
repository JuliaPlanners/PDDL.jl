# Built in operators, functions, and effects

"""
    equiv(a, b)

Equivalence in concrete and abstract domains. Defaults to `a == b`.
"""
equiv(a, b) = a == b

"""
    nequiv(a, b)

Non-equivalence in concrete or abstract domains. Defaults to `a != b`.
"""
nequiv(a, b) = a != b

"Mapping from PDDL comparison operators to Julia functions."
const comp_ops = Dict{Symbol,Function}(
    op => eval(op) for op in [:<=, :>=, :<, :>]
)
comp_ops[:(==)] = equiv
comp_ops[:(!=)] = nequiv

"Mapping from PDDL evaluation operators to Julia functions."
const eval_ops = Dict{Symbol,Function}(
    op => eval(op) for op in [:+, :-, :*, :/]
)

"Mapping from PDDL modification operators to Julia functions."
const modify_ops = Dict{Symbol,Function}(
    :increase => +,
    :decrease => -,
    Symbol("scale-up") => *,
    Symbol("scale-down") => /
)
