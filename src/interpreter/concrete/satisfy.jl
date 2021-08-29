function satisfy(interpreter::ConcreteInterpreter,
                 domain::Domain, state::GenericState,
                 terms::AbstractVector{<:Term})
     # Quick check that avoids SLD resolution unless necessary
     sat = all(check(interpreter, domain, state, t) for t in terms)
     if sat !== missing return sat end
     # Call SLD resolution only if there are free variables or axioms
     return !isempty(satisfiers(interpreter, domain, state, terms))
end

function satisfy(interpreter::ConcreteInterpreter,
                 domain::Domain, state::GenericState, term::Term)
    # Quick check that avoids SLD resolution unless necessary
    sat = check(interpreter, domain, state, term)
    if sat !== missing return sat end
    # Call SLD resolution only if there are free variables or axioms
    return !isempty(satisfiers(interpreter, domain, state, term))
end

function satisfiers(interpreter::ConcreteInterpreter,
                    domain::Domain, state::GenericState,
                    terms::AbstractVector{<:Term})
    # Initialize Julog knowledge base
    clauses = Clause[get_clauses(domain); collect(state.types); collect(state.facts)]
    # Pass in fluents and function definitions as a dictionary of functions
    funcs = merge(comp_ops, state.values, get_funcdefs(domain))
    return resolve(collect(terms), clauses; funcs=funcs, mode=:all)[2]
end

function satisfiers(interpreter::ConcreteInterpreter,
                    domain::Domain, state::GenericState, term::Term)
    return satisfiers(interpreter, domain, state, [term])
end

function check(interpreter::ConcreteInterpreter,
               domain::Domain, state::GenericState, term::Compound)
    sat = if term.name == :and
        all(check(interpreter, domain, state, a) for a in term.args)
    elseif term.name == :or
        any(check(interpreter, domain, state, a) for a in term.args)
    elseif term.name == :imply
        !check(interpreter, domain, state, term.args[1]) |
        check(interpreter, domain, state, term.args[2])
    elseif term.name == :not
        !check(interpreter, domain, state, term.args[1])
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
    elseif term.name in keys(comp_ops)
        comp_ops[term.name](evaluate(interpreter, domain, state, term.args[1]),
                            evaluate(interpreter, domain, state, term.args[2]))
    elseif is_func(term, domain)
        evaluate(interpreter, domain, state, term)::Bool
    else
        term = partialeval(domain, state, term)
        term in state.facts
    end
    return sat
end

function check(interpreter::ConcreteInterpreter,
               domain::Domain, state::GenericState, term::Const)
    if term in state.facts || term in state.types || term.name == true
        return true
    elseif is_func(term, domain) || is_derived(term, domain)
        return missing
    else
        return false
    end
end

function check(interpreter::ConcreteInterpreter,
               domain::Domain, state::GenericState, term::Var)
    return missing
end
