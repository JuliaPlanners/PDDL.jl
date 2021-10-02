function initstate(domain::CompiledDomain, problem::GenericProblem)
    # Construct state using interpreter, then convert to compiled
    generic_state = initstate(get_source(domain), problem)
    compiled_state = statetype(domain)(generic_state)
    return compiled_state
end

function initstate(domain::CompiledDomain, objtypes::AbstractDict, fluents)
    # Construct state using interpreter, then convert to compiled
    generic_state = initstate(get_source(domain), objtypes, fluents)
    compiled_state = statetype(domain)(generic_state)
    return compiled_state
end
