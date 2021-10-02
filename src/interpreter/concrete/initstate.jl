function initstate(interpreter::ConcreteInterpreter,
                   domain::GenericDomain, problem::GenericProblem)
    return initstate(interpreter, domain, problem.objtypes, problem.init)
end

function initstate(interpreter::ConcreteInterpreter,
                   domain::GenericDomain, objtypes::AbstractDict)
   types = Set{Term}([Compound(ty, Term[o]) for (o, ty) in objtypes])
   return GenericState(types, Set{Term}(), Dict{Symbol,Any}())
end

function initstate(interpreter::ConcreteInterpreter,
                   domain::GenericDomain, objtypes::AbstractDict,
                   fluents::AbstractVector)
    state = initstate(interpreter, domain, objtypes)
    for t in fluents
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

function initstate(interpreter::ConcreteInterpreter,
                   domain::GenericDomain, objtypes::AbstractDict,
                   fluents::AbstractDict)
    state = initstate(interpreter, domain, objtypes)
    for (name, val) in fluents
        setfluent!(state, val, name)
    end
    return state
end
