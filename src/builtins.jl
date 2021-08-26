# Built in operators, functions, and effects

"Mapping from PDDL comparison operators to Julia functions."
const comp_ops = Dict{Symbol,Function}(
    op => eval(op) for op in [:(==), :<=, :>=, :<, :>, :(!=)]
)

"Mapping from PDDL modification operators to Julia functions."
const modify_ops = Dict{Symbol,Function}(
    :increase => +,
    :decrease => -,
    Symbol("scale-up") => *,
    Symbol("scale-down") => /
)
