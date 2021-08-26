function regress(domain::GenericDomain, state::GenericState,
                 act::GenericAction, args; as_diff::Bool=false,
                 check::Bool=true, fail_mode::Symbol=:error)
    # Check whether action is relevant
    if check && !relevant(domain, state, act, args)
        if fail_mode == :no_op return as_diff ? Diff() : state end
        error("Effect $(act.effect) is not relevant.") # Error by default
    end
    subst = Subst(var => val for (var, val) in zip(act.args, args))
    precond = substitute(act.precond, subst)
    effect = substitute(act.effect, subst)
    # Compute regression difference as Precond - Additions
    # TODO: Handle conditional effects, disjunctive preconditions, etc.
    pre_diff = precond_diff(domain, state, precond)
    eff_diff = effect_diff(domain, state, effect)
    append!(pre_diff.del, eff_diff.add)
    return as_diff ? pre_diff : update(state, pre_diff)
end
