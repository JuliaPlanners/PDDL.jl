function relevant(domain::GenericDomain, state::GenericState;
                  strict::Bool=false)
    actions = Term[]
    for act in values(domain.actions)
        # Compute postconditions from the action's effect
        diff = effect_diff(domain, state, act.effect)
        addcond = strict ? diff.add : [Compound(:or, diff.add)]
        delcond = [@julog(not(:t)) for t in diff.del]
        typecond = [@julog($ty(:v)) for (v, ty) in zip(act.args, act.types)]
        # Include type conditions when necessary for correctness
        if any(has_func(c, domain) ||
               has_quantifier(c) for c in [addcond; delcond])
            conds = [typecond; addcond; delcond]
        else
            conds = [addcond; typecond; delcond]
        end
        # Find all substitutions that satisfy the postconditions
        subst = satisfiers(domain, state, conds)
        if length(subst) == 0 continue end
        for s in subst
            args = [get(s, var, var) for var in act.args]
            if any(!is_ground(a) for a in args) continue end
            term = isempty(args) ? Const(act.name) : Compound(act.name, args)
            push!(actions, term)
        end
    end
    return actions
end

function relevant(domain::GenericDomain, state::GenericState,
                  act::GenericAction, args; strict::Bool=false)
   if any(!is_ground(a) for a in args)
       error("Not all arguments are ground.")
   end
   subst = Subst(var => val for (var, val) in zip(act.args, args))
   # Compute postconditions from the action's effect
   diff = effect_diff(domain, state, substitute(act.effect, subst))
   postcond = Term[strict ? diff.add : Compound(:or, diff.add);
                   [@julog(not(:t)) for t in diff.del]]
   # Construct type conditions of the form "type(val)"
   typecond = (all(ty == :object for ty in act.types) ? Term[] :
               [@julog($ty(:v)) for (v, ty) in zip(args, act.types)])
   # Check whether postconditions hold
   return satisfy(domain, state, [postcond; typecond])
end

relevant(domain::GenericDomain, state::GenericState, act::Term; kwargs...) =
    relevant(domain, state, domain.actions[act.name], act.args; kwargs...)
