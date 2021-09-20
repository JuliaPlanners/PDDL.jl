function initstate(interpreter::AbstractInterpreter,
                   domain::AbstractedDomain, problem::GenericProblem)
    concrete_state = initstate(ConcreteInterpreter(), domain.domain, problem)
    absdom = AbstractedDomain(domain, interpreter)
    return abstractstate(absdom, concrete_state)
end
