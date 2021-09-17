"Abstractly interpreted PDDL domain."
struct AbstractedDomain <: Domain
    domain::Domain
    interpreter::AbstractInterpreter
end

AbstractedDomain(domain::Domain; options...) =
    AbstractedDomain(domain, AbstractInterpreter(; options...))

Base.copy(domain::AbstractedDomain) = deepcopy(domain)

get_name(domain::AbstractedDomain) = get_name(domain.domain)

get_requirements(domain::AbstractedDomain) = get_requirements(domain.domain)

get_types(domain::AbstractedDomain) = get_types(domain.domain)

get_constants(domain::AbstractedDomain) = get_constants(domain.domain)

get_constypes(domain::AbstractedDomain) = get_constypes(domain.domain)

get_predicates(domain::AbstractedDomain) = get_predicates(domain.domain)

get_functions(domain::AbstractedDomain) = get_functions(domain.domain)

get_funcdefs(domain::AbstractedDomain) = get_funcdefs(domain.domain)

get_fluents(domain::AbstractedDomain) = get_fluents(domain.domain)

get_axioms(domain::AbstractedDomain) = get_axioms(domain.domain)

get_actions(domain::AbstractedDomain) = get_actions(domain.domain)

## Forward methods from abstracted domains to abstract interpreter ##

satisfy(domain::AbstractedDomain, state::State, term::Term) =
    satisfy(domain.interpreter, domain, state, term)
satisfy(domain::AbstractedDomain, state::State, terms::AbstractVector{<:Term}) =
    satisfy(domain.interpreter, domain, state, terms)

satisfiers(domain::AbstractedDomain, state::State, term::Term) =
    satisfiers(domain.interpreter, domain, state, term)
satisfiers(domain::AbstractedDomain, state::State, terms::AbstractVector{<:Term}) =
    satisfiers(domain.interpreter, domain, state, terms)

evaluate(domain::AbstractedDomain, state::State, term::Term) =
    evaluate(domain.interpreter, domain, state, term)

initstate(domain::AbstractedDomain, problem::Problem) =
    initstate(domain.interpreter, domain, problem)

transition(domain::AbstractedDomain, state::State, action::Term; options...) =
    transition(domain.interpreter, domain, state, action; options...)
transition!(domain::AbstractedDomain, state::State, action::Term; options...) =
    transition!(domain.interpreter, domain, state, action; options...)

available(domain::AbstractedDomain, state::State, action::Action, args) =
    available(domain.interpreter, domain, state, action, args)
available(domain::AbstractedDomain, state::State) =
    available(domain.interpreter, domain, state)

execute(domain::AbstractedDomain, state::State, action::Action, args; options...) =
    execute(domain.interpreter, domain, state, action, args; options...)
execute!(domain::AbstractedDomain, state::State, action::Action, args; options...) =
    execute!(domain.interpreter, domain, state, action, args; options...)

relevant(domain::AbstractedDomain, state::State, action::Action, args) =
    relevant(domain.interpreter, domain, state, action, args)
relevant(domain::AbstractedDomain, state::State) =
    relevant(domain.interpreter, domain, state)

regress(domain::AbstractedDomain, state::State, action::Action, args; options...) =
    regress(domain.interpreter, domain, state, action, args; options...)
regress!(domain::AbstractedDomain, state::State, action::Action, args; options...) =
    regress!(domain.interpreter, domain, state, action, args; options...)
