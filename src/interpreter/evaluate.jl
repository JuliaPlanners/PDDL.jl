function evaluate(interpreter::Interpreter,
                  domain::Domain, state::GenericState, term::Term)
    # Evaluate formula as fully as possible
    val = partialeval(domain, state, term)
    # Return if formula evaluates to a Const
    if isa(val, Const) && (!isa(val.name, Symbol) || !is_fluent(val, domain))
        return val.name
    end
    # If val is not a Const, check if holds true in the state
    return satisfy(interpreter, domain, state, val)
end
