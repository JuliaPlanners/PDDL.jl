"Evaluate formula as fully as possible."
function partialeval(domain::Domain, state::GenericState, term::Term)
    if isempty(get_functions(domain)) return term end
    funcs = merge(state.values, get_funcdefs(domain))
    return eval_term(term, Subst(), funcs)
end

"""
    find_matches(term, state, domain=nothing)

Returns a list of all matching substitutions of `term` with respect to
a given `state` and `domain`.
"""
function find_matches(domain::GenericDomain, state::GenericState, term::Term)
    if term.name in keys(state.values)
        clauses = Vector{Clause}(get_fluents(state))
        _, subst = resolve(term, clauses; mode=:all)
    else
        clauses = isnothing(domain) ? Clause[] : get_clauses(domain)
        clauses = Clause[clauses; collect(state.types); collect(state.facts)]
        funcs = state.values
        _, subst = resolve(term, clauses; funcs=funcs, mode=:all)
    end
    matches = Term[substitute(term, s) for s in subst]
    return matches
end
