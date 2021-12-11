# Forward interface methods to concrete interpreter #

satisfy(domain::GroundDomain, state::State, term::Term) =
    satisfy(ConcreteInterpreter(), domain, state, term)
satisfy(domain::GroundDomain, state::State, terms::AbstractVector{<:Term}) =
    satisfy(ConcreteInterpreter(), domain, state, terms)

satisfiers(domain::GroundDomain, state::State, term::Term) =
    satisfiers(ConcreteInterpreter(), domain, state, term)
satisfiers(domain::GroundDomain, state::State, terms::AbstractVector{<:Term}) =
    satisfiers(ConcreteInterpreter(), domain, state, terms)

evaluate(domain::GroundDomain, state::State, term::Term) =
    evaluate(ConcreteInterpreter(), domain, state, term)

initstate(domain::GroundDomain, problem::Problem) =
    initstate(ConcreteInterpreter(), domain, problem)
initstate(domain::GroundDomain, objtypes::AbstractDict, fluents) =
    initstate(ConcreteInterpreter(), domain, objtypes, fluents)

goalstate(domain::GroundDomain, problem::Problem) =
    goalstate(ConcreteInterpreter(), domain, problem)
goalstate(domain::GroundDomain, objtypes::AbstractDict, terms) =
    goalstate(ConcreteInterpreter(), domain, objtypes, terms)

update!(domain::GroundDomain, state::State, diff::Diff) =
    update!(ConcreteInterpreter(), domain, state, diff)
update(domain::GroundDomain, state::State, diff::Diff) =
    update(ConcreteInterpreter(), domain, state, diff)
