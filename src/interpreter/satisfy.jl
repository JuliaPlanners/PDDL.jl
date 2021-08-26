function satisfy(domain::GenericDomain, state::GenericState,
                 terms::AbstractVector{<:Term})
     # Quick check that avoids SLD resolution unless necessary
     sat = all(check_term(domain, state, t) for t in terms)
     if sat !== missing return sat end
     # Call SLD resolution only if there are free variables or axioms
     return !isempty(satisfiers(domain, state, terms))
end

function satisfy(domain::GenericDomain, state::GenericState, term::Term)
    # Quick check that avoids SLD resolution unless necessary
    sat = check_term(domain, state, term)
    if sat !== missing return sat end
    # Call SLD resolution only if there are free variables or axioms
    return !isempty(satisfiers(domain, state, term))
end

function check_term(domain::GenericDomain, state::GenericState, term::Compound)
    sat = if term.name == :and
        all(check_term(domain, state, a) for a in term.args)
    elseif term.name == :or
        any(check_term(domain, state, a) for a in term.args)
    elseif term.name == :imply
        !check_term(domain, state, term.args[1]) |
        check_term(domain, state, term.args[2])
    elseif term.name == :not
        !check_term(domain, state, term.args[1])
    elseif term.name == :forall
        missing
    elseif term.name == :exists
        missing
    elseif !is_ground(term)
        missing
    elseif is_derived(term, domain)
        missing
    elseif is_type(term, domain) && has_subtypes(term, domain)
        missing
    elseif term.name in keys(comp_ops)
        comp_ops[term.name](evaluate(domain, state, term.args[1]),
                            evaluate(domain, state, term.args[2]))
    elseif is_func(term, domain)
        evaluate(domain, state, term)::Bool
    else
        term = partial_eval(domain, state, term)
        term in state.facts || term in state.types ||
        (!isempty(get_constants(domain)) && term in get_const_facts(domain))
    end
    return sat
end

function check_term(domain::GenericDomain, state::GenericState, term::Const)
    if term in state.facts || term in state.types || term.name == true
        return true
    elseif is_func(term, domain) || is_derived(term, domain)
        return missing
    else
        return false
    end
end

function check_term(domain::GenericDomain, state::GenericState, term::Var)
    return missing
end

function satisfiers(domain::GenericDomain, state::GenericState,
                    terms::AbstractVector{<:Term})
    # Initialize Julog knowledge base
    clauses = Clause[get_clauses(domain);
                     collect(state.types);
                     collect(state.facts)]
    # Pass in fluents and function definitions as a dictionary of functions
    funcs = merge(comp_ops, state.values, domain.funcdefs)
    return resolve(collect(terms), clauses; funcs=funcs, mode=:all)[2]
end

satisfiers(domain::GenericDomain, state::GenericState, term::Term) =
    satisfiers(domain, state, [term])
