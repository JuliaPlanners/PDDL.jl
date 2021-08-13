function satisfy(domain::GenericDomain, state::GenericState,
                 terms::AbstractVector{<:Term})
    # Do quick check as to whether formulae are in the set of facts
    function in_facts(f::Term)
        if !isempty(state.values)
            f = eval_term(f, Subst(), state.values) end
        if f in state.facts || f in state.types || f in get_const_facts(domain)
            return true end
        if f.name in Julog.comp_ops || f.name in keys(state.values)
            return eval_term(f, Subst(), state.values).name == true end
        return false
    end
    if all(f -> f.name == :not ? !in_facts(f.args[1]) : in_facts(f), terms)
        return true end
    # Initialize Julog knowledge base
    clauses = Clause[get_clauses(domain);
                     collect(state.types); collect(state.facts)]
    # Pass in fluents and function definitions as a dictionary of functions
    funcs = merge(state.values, domain.funcdefs)
    return resolve(collect(terms), clauses; funcs=funcs, mode=:any)[1]
end

satisfy(domain::GenericDomain, state::GenericState, term::Term) =
    satisfy(domain, state, [term])

function satisfiers(domain::GenericDomain, state::GenericState,
                    terms::AbstractVector{<:Term})
    # Initialize Julog knowledge base
    clauses = Clause[get_clauses(domain);
                     collect(state.types); collect(state.facts)]
    # Pass in fluents and function definitions as a dictionary of functions
    funcs = merge(state.values, domain.funcdefs)
    return resolve(collect(terms), clauses; funcs=funcs, mode=:all)[2]
end

satisfiers(domain::GenericDomain, state::GenericState, term::Term) =
    satisfiers(domain, state, [term])
