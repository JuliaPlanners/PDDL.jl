## Forward methods from concrete domains to concrete interpreter ##

const ConcreteDomain = GenericDomain

satisfy(domain::ConcreteDomain, state::State, term::Term) =
    satisfy(ConcreteInterpreter(), domain, state, term)
satisfy(domain::ConcreteDomain, state::State, terms::AbstractVector{<:Term}) =
    satisfy(ConcreteInterpreter(), domain, state, terms)

satisfiers(domain::ConcreteDomain, state::State, term::Term) =
    satisfiers(ConcreteInterpreter(), domain, state, term)
satisfiers(domain::ConcreteDomain, state::State, terms::AbstractVector{<:Term}) =
    satisfiers(ConcreteInterpreter(), domain, state, terms)

evaluate(domain::ConcreteDomain, state::State, term::Term) =
    evaluate(ConcreteInterpreter(), domain, state, term)

initstate(domain::ConcreteDomain, problem::Problem) =
    initstate(ConcreteInterpreter(), domain, problem)

transition(domain::ConcreteDomain, state::State, action::Term) =
    transition(ConcreteInterpreter(), domain, state, action)

available(domain::ConcreteDomain, state::State, action::Action, args) =
    available(ConcreteInterpreter(), domain, state, action, args)
available(domain::ConcreteDomain, state::State) =
    available(ConcreteInterpreter(), domain, state)

execute(domain::ConcreteDomain, state::State, action::Action, args; options...) =
    execute(ConcreteInterpreter(), domain, state, action, args; options...)

relevant(domain::ConcreteDomain, state::State, action::Action, args) =
    relevant(ConcreteInterpreter(), domain, state, action, args)
relevant(domain::ConcreteDomain, state::State) =
    relevant(ConcreteInterpreter(), domain, state)

regress(domain::ConcreteDomain, state::State, action::Action, args; options...) =
    regress(ConcreteInterpreter(), domain, state, action, args; options...)
