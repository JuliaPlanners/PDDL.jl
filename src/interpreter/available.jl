function available(domain::GenericDomain, state::GenericState)
    # Ground all action definitions with arguments
    actions = Term[]
    for act in values(domain.actions)
        typecond = (@julog($ty(:v)) for (v, ty) in zip(act.args, act.types))
        # Include type conditions when necessary for correctness
        p = act.precond
        if has_func(p, domain) || has_derived(p, domain) || has_quantifier(p)
            conds = prepend!(flatten_conjs(p), typecond)
        elseif domain.requirements[:typing]
            conds = append!(flatten_conjs(p), typecond)
        else
            conds = flatten_conjs(p)
        end
        # Find all substitutions that satisfy preconditions
        subst = satisfiers(domain, state, conds)
        if length(subst) == 0 continue end
        for s in subst
            args = [s[v] for v in act.args if v in keys(s)]
            if any(!is_ground(a) for a in args) continue end
            term = isempty(args) ? Const(act.name) : Compound(act.name, args)
            push!(actions, term)
        end
    end
    return actions
end

function available(domain::GenericDomain, state::GenericState,
                   act::GenericAction, args)
    if any(!is_ground(a) for a in args)
       error("Not all arguments are ground.")
    end
    subst = Subst(var => val for (var, val) in zip(act.args, args))
    # Construct type conditions of the form "type(val)"
    typecond = (all(ty == :object for ty in act.types) ? Term[] :
               [@julog($ty(:v)) for (v, ty) in zip(args, act.types)])
    # Check whether preconditions hold
    precond = substitute(act.precond, subst)
    conds = has_func(precond, domain) || has_quantifier(precond) ?
        [typecond; precond] : [precond; typecond]
    return satisfy(domain, state, conds)
end
