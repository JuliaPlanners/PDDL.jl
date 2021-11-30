function goalstate(interpreter::ConcreteInterpreter,
                   domain::Domain, problem::GenericProblem)
    types = Set{Term}([Compound(ty, Term[o]) for (o, ty) in problem.objtypes])
    facts = Set{Term}(flatten_conjs(problem.goal))
    state = GenericState(types, facts, Dict{Symbol,Any}())
    return state
end

function goalstate(interpreter::ConcreteInterpreter,
                   domain::Domain, objtypes::AbstractDict, terms)
    types = Set{Term}([Compound(ty, Term[o]) for (o, ty) in objtypes])
    goal = GenericState(types, Set{Term}(), Dict{Symbol,Any}())
    for t in flatten_conjs(terms)
        if t.name == :(==) # Function equality
            @assert length(t.args) == 2 "Assignments must have two arguments."
            term, val = t.args[1], t.args[2]
            @assert(is_func(term, domain) && !is_attached_func(term, domain),
                    "Unrecognized function $(term.name).")
            @assert(is_ground(term), "Assigned terms must be ground.")
            @assert(isa(val, Const), "Terms must be equal to constants.")
            goal[term] = val.name
        elseif is_pred(t, domain) # Predicates
            push!(goal.facts, t)
        else
            error("Term $t in $terms cannot be handled.")
        end
    end
    return goal
end
