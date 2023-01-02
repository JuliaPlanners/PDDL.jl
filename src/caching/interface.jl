# Define cached interface methods

@_cached :satisfy satisfy(domain::Domain, state::State, terms::AbstractVector{<:Term})

@_cached :satisfiers satisfiers(domain::Domain, state::State, terms::AbstractVector{<:Term})

@_cached :evaluate evaluate(domain::Domain, state::State, term::Term)

@_cached :available available(domain::Domain, state::State)

@_cached :relevant relevant(domain::Domain, state::State)

@_cached :is_available available(domain::Domain, state::State, term::Term)

@_cached :is_relevant relevant(domain::Domain, state::State, term::Term)

@_cached :transition transition(domain::Domain, state::State, term::Term; options...)

@_cached :execute execute(domain::Domain, state::State, term::Term; options...)

@_cached :regress regress(domain::Domain, state::State, term::Term; options...)

# Forward uncached interface methods

satisfy(domain::CachedDomain, state::State, term::Term) =
    satisfy(domain, state, [term])
satisfiers(domain::CachedDomain, state::State, term::Term) =
    satisfiers(domain.source, state, [term])

initstate(domain::CachedDomain, problem::Problem) =
    initstate(domain.source, problem)
initstate(domain::CachedDomain, objtypes::AbstractDict, fluents) =
    initstate(domain.source, objtypes, fluents)

goalstate(domain::CachedDomain, problem::Problem) =
    goalstate(domain.source, problem)
goalstate(domain::CachedDomain, objtypes::AbstractDict, terms) =
    goalstate(domain.source, objtypes, terms)

transition!(domain::CachedDomain, state::State, action::Term; options...) =
    transition!(domain.source, state, action; options...)
transition!(domain::CachedDomain, state::State, actions; options...) =
    transition!(domain.source, state, action; options...)

available(domain::CachedDomain, state::State, action::Action, args) =
    available(domain, state, Compound(get_name(action), args))

execute(domain::CachedDomain, state::State, action::Action, args; options...) =
    execute(domain, state, Compound(get_name(action), args); options...)
execute!(domain::CachedDomain, state::State, action::Action, args; options...) =
    execute!(domain.source, state, action, args; options...)
execute!(domain::CachedDomain, state::State, action::Term; options...) =
    execute!(domain.source, state, action; options...)

relevant(domain::CachedDomain, state::State, action::Action, args) =
    relevant(domain, state, Compound(get_name(action), args))

regress(domain::CachedDomain, state::State, action::Action, args; options...) =
    regress(domain, state, Compound(get_name(action), args); options...)
regress!(domain::CachedDomain, state::State, action::Action, args; options...) =
    regress!(domain.source, state, action, args; options...)
regress!(domain::CachedDomain, state::State, action::Term; options...) =
    regress!(domain.source, state, action; options...)

update!(domain::CachedDomain, state::State, diff::Diff) =
    update!(domain.source, state, diff)
update(domain::CachedDomain, state::State, diff::Diff) =
    update(domain.source, state, diff)
