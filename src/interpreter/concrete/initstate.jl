function initstate(interpreter::ConcreteInterpreter,
                   domain::GenericDomain, problem::GenericProblem)
    types = Set{Term}([Compound(ty, Term[o]) for (o, ty) in problem.objtypes])
    state = GenericState(types, Set{Term}(), Dict{Symbol,Any}())
    for t in problem.init
        if t.name == :(==) # Non-Boolean fluents
            @assert length(t.args) == 2 "Assignments must have two arguments."
            term, val = t.args[1], t.args[2]
            @assert !isa(term, Var) "Initial terms cannot be unbound variables."
            state[term] = evaluate(domain, state, val)
        else # Boolean fluents
            push!(state.facts, t)
        end
    end
    return state
end
