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
initstate(domain::ConcreteDomain, objtypes::AbstractDict, fluents) =
    initstate(ConcreteInterpreter(), domain, objtypes, fluents)

goalstate(domain::ConcreteDomain, problem::Problem) =
    goalstate(ConcreteInterpreter(), domain, problem)
goalstate(domain::ConcreteDomain, objtypes::AbstractDict, terms) =
    goalstate(ConcreteInterpreter(), domain, objtypes, terms)

transition(domain::ConcreteDomain, state::State, action::Term; options...) =
    transition(ConcreteInterpreter(), domain, state, action; options...)
transition!(domain::ConcreteDomain, state::State, action::Term; options...) =
    transition!(ConcreteInterpreter(), domain, state, action; options...)

available(domain::ConcreteDomain, state::State, action::Action, args) =
    available(ConcreteInterpreter(), domain, state, action, args)
available(domain::ConcreteDomain, state::State) =
    available(ConcreteInterpreter(), domain, state)

execute(domain::ConcreteDomain, state::State, action::Action, args; options...) =
    execute(ConcreteInterpreter(), domain, state, action, args; options...)
execute!(domain::ConcreteDomain, state::State, action::Action, args; options...) =
    execute!(ConcreteInterpreter(), domain, state, action, args; options...)

relevant(domain::ConcreteDomain, state::State, action::Action, args) =
    relevant(ConcreteInterpreter(), domain, state, action, args)
relevant(domain::ConcreteDomain, state::State) =
    relevant(ConcreteInterpreter(), domain, state)

regress(domain::ConcreteDomain, state::State, action::Action, args; options...) =
    regress(ConcreteInterpreter(), domain, state, action, args; options...)
regress!(domain::ConcreteDomain, state::State, action::Action, args; options...) =
    regress!(ConcreteInterpreter(), domain, state, action, args; options...)
