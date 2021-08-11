function evaluate(domain::GenericDomain, state::GenericState, term::Term)
    # Evaluate formula as fully as possible
    funcs = merge(state.fluents, domain.funcdefs)
    val = eval_term(term, Subst(), funcs)
    # Return if formula evaluates to a Const
    if (isa(val, Const) && (!isa(val.name, Symbol) ||
                            !(val.name in keys(domain.predicates)) &&
                            !(val.name in keys(domain.functions))))
        return val.name
    end
    # If val is not a Const, check if holds true in the state
    return satisfy(domain, state, val)
end
