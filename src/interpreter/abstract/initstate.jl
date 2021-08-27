"Construct initial state from problem definition."
function initstate(interpreter::AbstractInterpreter,
                   domain::Domain, problem::GenericProblem)
    types = Set{Term}([@julog($ty(:o)) for (o, ty) in problem.objtypes])
    state = GenericState(types, Set{Term}(), Dict{Symbol,Any}())
    for t in problem.init
        if t.name == :(==) # Non-Boolean fluents
            term, val = t.args[1], t.args[2]
            @assert !isa(term, Var) "Initial terms cannot be unbound variables."
            @assert isa(val, Const) "Terms must be initialized to constants."
            # Look up abstraction based on fluent type
            type = get_functions(domain)[term.name].type
            # Convert from concrete to abstract value
            state[term] = interpreter.abstractions[type](val.name)
        else # Boolean fluents
            push!(state.facts, t)
        end
    end
    return state
end
