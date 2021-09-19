function evaluate(interpreter::Interpreter,
                  domain::Domain, state::GenericState, term::Term)
    # Evaluate formula as fully as possible
    val = partialeval(domain, state, term)
    # Return if formula evaluates to a Const
    if isa(val, Const) && (!isa(val.name, Symbol) || !is_pred(val, domain))
        return val.name
    elseif is_pred(val, domain) # Satisfy if we evaluate to a predicate
        return satisfy(interpreter, domain, state, val)
    elseif val in get_objects(state) # Return object constant
        return val
    else
        error("Unrecognized term $term.")
    end
end
