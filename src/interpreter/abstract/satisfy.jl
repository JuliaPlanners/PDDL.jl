function satisfy(interpreter::AbstractInterpreter,
                 domain::Domain, state::GenericState,
                 terms::AbstractVector{<:Term})
     # Quick check that avoids SLD resolution unless necessary
     sat = all4(check(interpreter, domain, state, to_nnf(t)) for t in terms)
     if sat !== missing return (sat == true || sat == both) end
     # Call SLD resolution only if there are free variables or axioms
     return !isempty(satisfiers(interpreter, domain, state, terms))
end

function satisfy(interpreter::AbstractInterpreter,
                 domain::Domain, state::GenericState, term::Term)
    # Convert to NNF
    term = to_nnf(term)
    # Quick check that avoids SLD resolution unless necessary
    sat = check(interpreter, domain, state, term)
    if sat !== missing return (sat == true || sat == both) end
    # Call SLD resolution only if there are free variables or axioms
    return !isempty(satisfiers(interpreter, domain, state, term))
end

function satisfiers(interpreter::AbstractInterpreter,
                    domain::Domain, state::GenericState,
                    terms::AbstractVector{<:Term})
    # Reify negations
    terms = [reify_negations(to_nnf(t), domain) for t in terms]
    # Initialize Julog knowledge base
    clauses = Clause[get_clauses(domain); # get_negation_clauses(domain);
                     collect(state.types); collect(state.facts)]
    # Pass in fluents and function definitions as a dictionary of functions
    funcs = get_eval_funcs(domain, state, include_both=true)
    # Reorder query to reduce search time
    terms = reorder_query(domain, collect(terms))
    # Find satisfying substitutions via SLD-resolution
    _, subst = resolve(terms, clauses; funcs=funcs, mode=:all, search=:dfs)
    return subst
end

function satisfiers(interpreter::AbstractInterpreter,
                    domain::Domain, state::GenericState, term::Term)
    return satisfiers(domain, state, [term])
end

function check(interpreter::AbstractInterpreter,
               domain::Domain, state::GenericState, term::Compound)
    sat = if term.name == :and
        all4(check(interpreter, domain, state, a) for a in term.args)
    elseif term.name == :or
        any4(check(interpreter, domain, state, a) for a in term.args)
    elseif term.name == :imply
        !check(interpreter, domain, state, term.args[1]) |
        check(interpreter, domain, state, term.args[2])
    elseif term.name == :not
        !check(interpreter, domain, state, term.args[1]) |
        check(interpreter, domain, state, negate(term.args[1]))
    elseif term.name == :forall
        missing
    elseif term.name == :exists
        missing
    elseif !is_ground(term)
        missing
    elseif is_derived(term, domain)
        missing
    elseif is_type(term, domain)
        if has_subtypes(term, domain)
            missing
        elseif term in state.types
            true
        elseif !isempty(get_constants(domain))
            domain.constypes[term.args[1]] == term.name
        else
            false
        end
    elseif is_global_pred(term)
        evaluate(interpreter, domain, state, term)::BooleanAbs
    elseif is_func(term, domain)
        evaluate(interpreter, domain, state, term)::BooleanAbs
    else
        term in state.facts
    end
    return sat
end

function check(interpreter::AbstractInterpreter,
               domain::Domain, state::GenericState, term::Const)
    if term in state.facts || term in state.types || term.name == true
        return true
    elseif is_func(term, domain) || is_derived(term, domain)
        return missing
    else
        return false
    end
end

function check(interpreter::AbstractInterpreter,
               domain::Domain, state::GenericState, term::Var)
    return missing
end
