"Construct initial state from problem definition."
function initstate(domain::GenericDomain, problem::GenericProblem)
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

"Construct goal state from problem definition."
function goalstate(domain::GenericDomain, problem::GenericProblem)
    types = Set{Term}([@julog($ty(:o)) for (o, ty) in problem.objtypes])
    facts = Set{Term}(flatten_conjs(problem.goal))
    state = GenericState(types, facts, Dict{Symbol,Any}())
    return state
end
