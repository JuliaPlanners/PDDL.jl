function relevant(interpreter::Interpreter, domain::Domain, state::State)
    actions = Term[]
    for act in values(get_actions(domain))
        act_name = get_name(act)
        act_vars, act_types = get_argvars(act), get_argtypes(act)
        # Compute postconditions from the action's effect
        diff = effect_diff(domain, state, get_effect(act))
        addcond = [Compound(:or, diff.add)]
        delcond = [@julog(not(:t)) for t in diff.del]
        typecond = [@julog($ty(:v)) for (v, ty) in zip(act_vars, act_types)]
        # Include type conditions when necessary for correctness
        if any(has_func(c, domain) ||
               has_quantifier(c) for c in [addcond; delcond])
            conds = [typecond; addcond; delcond]
        else
            conds = [addcond; typecond; delcond]
        end
        # Find all substitutions that satisfy the postconditions
        subst = satisfiers(interpreter, domain, state, conds)
        if isempty(subst) continue end
        for s in subst
            args = [get(s, var, var) for var in act_vars]
            if any(!is_ground(a) for a in args) continue end
            term = isempty(args) ? Const(act_name) : Compound(act_name, args)
            push!(actions, term)
        end
    end
    return actions
end

function relevant(interpreter::Interpreter,
                  domain::Domain, state::State, action::Action, args)
   if any(!is_ground(a) for a in args)
       error("Not all arguments are ground.")
   end
   act_vars, act_types = get_argvars(action), get_argtypes(action)
   subst = Subst(var => val for (var, val) in zip(act_vars, args))
   # Compute postconditions from the action's effect
   diff = effect_diff(domain, state, substitute(get_effect(action), subst))
   postcond = Term[Compound(:or, diff.add); [@julog(not(:t)) for t in diff.del]]
   # Construct type conditions of the form "type(val)"
   typecond = (all(ty == :object for ty in act_types) ? Term[] :
               [@julog($ty(:v)) for (v, ty) in zip(args, act_types)])
   # Check whether postconditions hold
   return satisfy(interpreter, domain, state, [postcond; typecond])
end
