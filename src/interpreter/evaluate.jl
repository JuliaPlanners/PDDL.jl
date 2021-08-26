function evaluate(domain::GenericDomain, state::GenericState, term::Term)
    # Evaluate formula as fully as possible
    val = partial_eval(domain, state, term)
    # Return if formula evaluates to a Const
    if isa(val, Const) && (!isa(val.name, Symbol) || !is_fluent(val, domain))
        return val.name
    end
    # If val is not a Const, check if holds true in the state
    return satisfy(domain, state, val)
end

"Evaluate formula as fully as possible."
function partial_eval(domain::GenericDomain, state::GenericState, term::Term)
    if isempty(get_functions(domain)) return term end
    funcs = merge(state.values, domain.funcdefs)
    return eval_term(term, Subst(), funcs)
end
