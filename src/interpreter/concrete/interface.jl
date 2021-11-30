# Forward methods from generic domains to concrete interpreter #

satisfy(domain::GenericDomain, state::State, term::Term) =
    satisfy(ConcreteInterpreter(), domain, state, term)
satisfy(domain::GenericDomain, state::State, terms::AbstractVector{<:Term}) =
    satisfy(ConcreteInterpreter(), domain, state, terms)

satisfiers(domain::GenericDomain, state::State, term::Term) =
    satisfiers(ConcreteInterpreter(), domain, state, term)
satisfiers(domain::GenericDomain, state::State, terms::AbstractVector{<:Term}) =
    satisfiers(ConcreteInterpreter(), domain, state, terms)

evaluate(domain::GenericDomain, state::State, term::Term) =
    evaluate(ConcreteInterpreter(), domain, state, term)

initstate(domain::GenericDomain, problem::Problem) =
    initstate(ConcreteInterpreter(), domain, problem)
initstate(domain::GenericDomain, objtypes::AbstractDict) =
    initstate(ConcreteInterpreter(), domain, objtypes)
initstate(domain::GenericDomain, objtypes::AbstractDict, fluents) =
    initstate(ConcreteInterpreter(), domain, objtypes, fluents)

goalstate(domain::GenericDomain, problem::Problem) =
    goalstate(ConcreteInterpreter(), domain, problem)
goalstate(domain::GenericDomain, objtypes::AbstractDict, terms) =
    goalstate(ConcreteInterpreter(), domain, objtypes, terms)

transition(domain::GenericDomain, state::State, action::Term; options...) =
    transition(ConcreteInterpreter(), domain, state, action; options...)
transition!(domain::GenericDomain, state::State, action::Term; options...) =
    transition!(ConcreteInterpreter(), domain, state, action; options...)

available(domain::GenericDomain, state::State, action::Action, args) =
    available(ConcreteInterpreter(), domain, state, action, args)
available(domain::GenericDomain, state::State) =
    available(ConcreteInterpreter(), domain, state)

execute(domain::GenericDomain, state::State, action::Action, args; options...) =
    execute(ConcreteInterpreter(), domain, state, action, args; options...)
execute!(domain::GenericDomain, state::State, action::Action, args; options...) =
    execute!(ConcreteInterpreter(), domain, state, action, args; options...)

relevant(domain::GenericDomain, state::State, action::Action, args) =
    relevant(ConcreteInterpreter(), domain, state, action, args)
relevant(domain::GenericDomain, state::State) =
    relevant(ConcreteInterpreter(), domain, state)

regress(domain::GenericDomain, state::State, action::Action, args; options...) =
    regress(ConcreteInterpreter(), domain, state, action, args; options...)
regress!(domain::GenericDomain, state::State, action::Action, args; options...) =
    regress!(ConcreteInterpreter(), domain, state, action, args; options...)

update!(domain::GenericDomain, state::State, diff::Diff) =
    update!(ConcreteInterpreter(), domain, state, diff)
update(domain::GenericDomain, state::State, diff::Diff) =
    update(ConcreteInterpreter(), domain, state, diff)
