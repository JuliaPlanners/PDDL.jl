"""
    find_matches(term, state, domain=nothing)

Returns a list of all matching substitutions of `term` with respect to
a given `state` and `domain`.
"""
function find_matches(domain::GenericDomain, state::GenericState, term::Term)
    if term.name in keys(state.fluents)
        clauses = Vector{Clause}(get_fluents(state))
        _, subst = resolve(term, clauses; mode=:all)
    else
        clauses = isnothing(domain) ? Clause[] : get_clauses(domain)
        clauses = Clause[clauses; collect(state.types); collect(state.facts)]
        funcs = state.fluents
        _, subst = resolve(term, clauses; funcs=funcs, mode=:all)
    end
    matches = Term[substitute(term, s) for s in subst]
    return matches
end
