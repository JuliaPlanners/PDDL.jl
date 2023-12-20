function relevant(interpreter::Interpreter, domain::Domain, state::State)
    actions = Compound[]
    for act in values(get_actions(domain))
        act_name = get_name(act)
        act_vars, act_types = get_argvars(act), get_argtypes(act)
        # Compute postconditions from the action's effect
        diff = effect_diff(domain, state, get_effect(act))
        addcond = [Compound(:or, diff.add)]
        delcond = [pddl"(not $t)" for t in diff.del]
        typecond = [pddl"($ty $v)" for (v, ty) in zip(act_vars, act_types)]
        conds = [addcond; typecond; delcond]
        # Find all substitutions that satisfy the postconditions
        subst = satisfiers(interpreter, domain, state, conds)
        if isempty(subst) continue end
        for s in subst
            args = [get(s, var, var) for var in act_vars]
            if any(!is_ground(a) for a in args) continue end
            push!(actions, Compound(act_name, args))
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
   postcond = Term[Compound(:or, diff.add); [pddl"(not $t)" for t in diff.del]]
   # Construct type conditions of the form "type(val)"
   typecond = (all(ty == :object for ty in act_types) ? Term[] :
               [pddl"($ty $v)" for (v, ty) in zip(args, act_types)])
   # Check whether postconditions hold
   return satisfy(interpreter, domain, state, [postcond; typecond])
end
