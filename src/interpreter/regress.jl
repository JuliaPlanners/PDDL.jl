function regress(interpreter::Interpreter,
                 domain::Domain, state::State, action::Action, args;
                 check::Bool=true, fail_mode::Symbol=:error)
    # Check whether action is relevant
    if check && !relevant(interpreter, domain, state, action, args)
        if fail_mode == :no_op return state end
        action_str = Writer.write_formula(get_name(action), args)
        error("Could not revert $action_str:\n" *
              "Effect $(write_pddl(get_effect(action))) is not relevant.")
    end
    return regress!(interpreter, domain, copy(state), action, args; check=false)
end

function regress!(interpreter::Interpreter,
                  domain::Domain, state::State, action::Action, args;
                  check::Bool=true, fail_mode::Symbol=:error)
    # Check whether action is relevant
    if check && !relevant(interpreter, domain, state, action, args)
        if fail_mode == :no_op return state end
        action_str = Writer.write_formula(get_name(action), args)
        error("Could not revert $action_str:\n" *
              "Effect $(write_pddl(get_effect(action))) is not relevant.")
    end
    subst = Subst(var => val for (var, val) in zip(get_argvars(action), args))
    precond = substitute(get_precond(action), subst)
    effect = substitute(get_effect(action), subst)
    # Compute regression difference as Precond - Additions
    # TODO: Handle conditional effects, disjunctive preconditions, etc.
    pre_diff = precond_diff(domain, state, precond)
    eff_diff = effect_diff(domain, state, effect)
    append!(pre_diff.del, eff_diff.add)
    return update!(interpreter, domain, state, pre_diff)
end
