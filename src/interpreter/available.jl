function available(interpreter::Interpreter, domain::Domain, state::State)
    # Ground all action definitions with arguments
    actions = Term[]
    for act in values(get_actions(domain))
        act_name = get_name(act)
        act_vars, act_types = get_argvars(act), get_argtypes(act)
        # Include type conditions when necessary for correctness
        typecond = (@julog($ty(:v)) for (v, ty) in zip(act_vars, act_types))
        p = get_precond(act)
        if has_func(p, domain) || has_derived(p, domain) || has_quantifier(p)
            conds = prepend!(flatten_conjs(p), typecond)
        elseif get_requirements(domain)[:typing]
            conds = append!(flatten_conjs(p), typecond)
        else
            conds = flatten_conjs(p)
        end
        # Find all substitutions that satisfy preconditions
        subst = satisfiers(interpreter, domain, state, conds)
        if isempty(subst) continue end
        for s in subst
            args = [s[v] for v in act_vars if v in keys(s)]
            if any(!is_ground(a) for a in args) continue end
            term = isempty(args) ? Const(act_name) : Compound(act_name, args)
            push!(actions, term)
        end
    end
    return actions
end

function available(interpreter::Interpreter,
                   domain::Domain, state::State, action::Action, args)
    if any(!is_ground(a) for a in args)
       error("Not all arguments are ground.")
    end
    act_vars, act_types = get_argvars(action), get_argtypes(action)
    subst = Subst(var => val for (var, val) in zip(act_vars, args))
    # Construct type conditions of the form "type(val)"
    typecond = (all(ty == :object for ty in action.types) ? Term[] :
               [@julog($ty(:v)) for (v, ty) in zip(args, act_types)])
    # Check whether preconditions hold
    precond = substitute(get_precond(action), subst)
    conds = has_func(precond, domain) || has_quantifier(precond) ?
        [typecond; precond] : [precond; typecond]
    return satisfy(interpreter, domain, state, conds)
end
