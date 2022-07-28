"Check if term is static or composed of static subterms."
function is_static(term::Term, domain::Domain,
                   statics=infer_static_fluents(domain))
    if term.name in statics return true end
    fluents = constituents(term, domain)
    return all(f.name in statics for f in fluents)
end

"Infer fluents that are never modified by some action in a domain."
function infer_static_fluents(domain::Domain)
    affected = infer_affected_fluents(domain)
    static = setdiff(keys(get_fluents(domain)), affected)
    return collect(static)
end

"Simplify away static fluents within a `term`."
function simplify_statics(term::Term, domain::Domain, state::State,
                          statics=infer_static_fluents(domain))
    # Simplify logical compounds
    if term.name == :and
        new_args = nothing
        for (i, a) in enumerate(term.args)
            new_a = simplify_statics(a, domain, state, statics)
            new_a.name === false && return Const(false)
            if new_a !== a || new_args !== nothing
                new_args === nothing && (new_args = term.args[1:i-1])
                new_a.name !== true && push!(new_args, new_a)
            end
        end
        new_args === nothing && return term # All subterms were preserved
        isempty(new_args) && return Const(true) # All subterms were true
        return length(new_args) == 1 ? new_args[1] : Compound(:and, new_args)
    elseif term.name == :or
        new_args = nothing
        for (i, a) in enumerate(term.args)
            new_a = simplify_statics(a, domain, state, statics)
            new_a.name === true && return Const(true)
            if new_a !== a || new_args !== nothing
                new_args === nothing && (new_args = term.args[1:i-1])
                new_a.name !== false && push!(new_args, new_a)
            end
        end
        new_args === nothing && return term # All subterms were preserved
        isempty(new_args) && return Const(false) # All subterms were false
        return length(new_args) == 1 ? new_args[1] : Compound(:or, new_args)
    elseif term.name == :imply
        cond, query = term.args
        cond = simplify_statics(cond, domain, state, statics)
        cond.name == false && return Const(true)
        query = simplify_statics(query, domain, state, statics)
        cond.name == true && return query
        return Compound(:imply, Term[cond, query])
    elseif term.name == :not
        new_arg = simplify_statics(term.args[1], domain, state, statics)
        new_arg === term.args[1] && return term
        val = new_arg.name
        return val isa Bool ? Const(!val) : Compound(:not, Term[new_arg])
    elseif is_quantifier(term)
        typecond, body = term.args
        body = simplify_statics(body, domain, state, statics)
        body === term.args[2] && return term
        return Compound(term.name, Term[typecond, body])
    elseif is_static(term, domain, statics) && is_ground(term)
        # Simplify predicates that are static and ground
        if is_pred(term, domain)
            return Const(satisfy(domain, state, term))
        else
            return Const(evaluate(domain, state, term)::Bool)
        end
    else # Return term without simplifying
        return term
    end
end
