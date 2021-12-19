# Forward methods from abstracted domains to abstract interpreter #

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
initstate(domain::AbstractedDomain, objtypes::AbstractDict) =
    initstate(domain.interpreter, domain, objtypes)
initstate(domain::AbstractedDomain, objtypes::AbstractDict, fluents) =
    initstate(domain.interpreter, domain, objtypes, fluents)

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

update!(domain::AbstractedDomain, state::State, diff::Diff) =
    update!(domain.interpreter, domain, state, diff)
update(domain::AbstractedDomain, state::State, diff::Diff) =
    update(domain.interpreter, domain, state, diff)

widen!(domain::AbstractedDomain, state::State, diff::Diff) =
    widen!(domain.interpreter, domain, state, diff)
widen(domain::AbstractedDomain, state::State, diff::Diff) =
    widen(domain.interpreter, domain, state, diff)
