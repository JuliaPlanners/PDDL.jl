"Evaluate formula as fully as possible."
function partialeval(domain::Domain, state::GenericState, term::Term)
    funcs = merge(global_functions(), state.values, get_funcdefs(domain))
    return eval_term(term, Subst(), funcs)
end

"Get domain constant type declarations as a list of clauses."
function get_const_clauses(domain::Domain)
   return [@julog($ty(:o) <<= true) for (o, ty) in get_constypes(domain)]
end

"Get domain type hierarchy as a list of clauses."
function get_type_clauses(domain::Domain)
    clauses = [[Clause(@julog($ty(X)), Term[@julog($s(X))]) for s in subtys]
               for (ty, subtys) in get_typetree(domain) if length(subtys) > 0]
    return length(clauses) > 0 ? reduce(vcat, clauses) : Clause[]
end

"Get all proof-relevant Horn clauses for PDDL domain."
function get_clauses(domain::Domain)
   return [collect(values(get_axioms(domain)));
           get_const_clauses(domain); get_type_clauses(domain)]
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
