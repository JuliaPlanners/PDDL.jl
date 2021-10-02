function initstate(interpreter::AbstractInterpreter,
                   domain::AbstractedDomain, problem::GenericProblem)
    concrete_state = initstate(ConcreteInterpreter(), domain.domain, problem)
    absdom = AbstractedDomain(domain, interpreter)
    return abstractstate(absdom, concrete_state)
end

function initstate(interpreter::AbstractInterpreter,
                   domain::AbstractedDomain, objtypes::AbstractDict)
    concrete_state = initstate(ConcreteInterpreter(), domain.domain, objtypes)
    absdom = AbstractedDomain(domain, interpreter)
    return abstractstate(absdom, concrete_state)
end

function initstate(interpreter::AbstractInterpreter,
                   domain::AbstractedDomain, objtypes::AbstractDict, fluents)
    concrete_state = initstate(ConcreteInterpreter(),
                               domain.domain, objtypes, fluents)
    absdom = AbstractedDomain(domain, interpreter)
    return abstractstate(absdom, concrete_state)
end
