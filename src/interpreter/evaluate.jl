function evaluate(interpreter::Interpreter,
                  domain::Domain, state::GenericState, term::Term)
    # Evaluate formula as fully as possible
    val = partialeval(domain, state, term)
    # Return if formula evaluates to a Const
    if isa(val, Const) && (!isa(val.name, Symbol) || !is_pred(val, domain))
        return val.name
    elseif is_pred(val, domain) || is_type(val, domain) || is_logical_op(val)
        return satisfy(interpreter, domain, state, val)
    elseif val in get_objects(state) # Return object constant
        return val
    else
        error("Unrecognized term $term.")
    end
end
