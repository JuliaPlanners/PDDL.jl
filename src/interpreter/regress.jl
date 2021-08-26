function regress(domain::InterpretedDomain, state::State,
                 action::Action, args; as_diff::Bool=false,
                 check::Bool=true, fail_mode::Symbol=:error)
    # Check whether action is relevant
    if check && !relevant(domain, state, action, args)
        if fail_mode == :no_op return as_diff ? Diff() : state end
        error("Effect $(get_effect(action)) is not relevant.")
    end
    subst = Subst(var => val for (var, val) in zip(get_argvars(action), args))
    precond = substitute(get_precond(action), subst)
    effect = substitute(get_effect(action), subst)
    # Compute regression difference as Precond - Additions
    # TODO: Handle conditional effects, disjunctive preconditions, etc.
    pre_diff = precond_diff(domain, state, precond)
    eff_diff = effect_diff(domain, state, effect)
    append!(pre_diff.del, eff_diff.add)
    return as_diff ? pre_diff : update(state, pre_diff)
end
