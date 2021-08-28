function initstate(interpreter::ConcreteInterpreter,
                   domain::GenericDomain, problem::GenericProblem)
    types = Set{Term}([@julog($ty(:o)) for (o, ty) in problem.objtypes])
    state = GenericState(types, Set{Term}(), Dict{Symbol,Any}())
    for t in problem.init
        if t.name == :(==) # Non-Boolean fluents
            term, val = t.args[1], t.args[2]
            @assert !isa(term, Var) "Initial terms cannot be unbound variables."
            @assert isa(val, Const) "Terms must be initialized to constants."
            state[term] = val.name
        else # Boolean fluents
            push!(state.facts, t)
        end
    end
    return state
end

"""
    goalstate(domain::Domain, problem::Problem)
    goalstate(domain::Domain, state::State, terms)

Construct a (partial) goal state from a `domain` and `problem`, or from
a `domain`, initial `state` and goal `terms`.
"""
function goalstate(domain::GenericDomain, problem::GenericProblem)
    types = Set{Term}([@julog($ty(:o)) for (o, ty) in problem.objtypes])
    facts = Set{Term}(flatten_conjs(problem.goal))
    state = GenericState(types, facts, Dict{Symbol,Any}())
    return state
end

function goalstate(domain::GenericDomain, state::GenericState, terms)
    goal = GenericState(state.types, Set{Term}(), Dict{Symbol,Any}())
    for t in flatten_conjs(terms)
        if t.name == :(==) # Non-Boolean fluents
            term, val = t.args[1], t.args[2]
            @assert !isa(term, Var) "Assigned terms cannot be unbound variables."
            @assert isa(val, Const) "Terms must be equal to constants."
            goal[term] = val.name
        else # Boolean fluents
            push!(goal.facts, t)
        end
    end
    return goal
end
