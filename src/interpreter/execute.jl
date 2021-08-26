function execute(domain::Domain{<:Interpreted}, state::State,
                 action::Action, args; as_diff::Bool=false,
                 check::Bool=true, fail_mode::Symbol=:error)
    # Check whether references resolve and preconditions hold
    if check && !available(domain, state, action, args)
        if fail_mode == :no_op return as_diff ? no_effect() : state end
        error("Precondition $(get_precond(action)) does not hold.")
    end
    # Substitute arguments and preconditions
    # TODO : Check for non-ground terms outside of quantified formulae
    subst = Subst(var => val for (var, val) in zip(get_argvars(action), args))
    effect = substitute(get_effect(action), subst)
    # Compute effect as a state diffference
    diff = effect_diff(domain, state, effect)
    # Return either the difference or the updated state
    return as_diff ? diff : update(state, diff)
end

function execute(domain::Domain{<:Interpreted}, state::State,
                 actions::AbstractVector{<:Term};
                 as_diff::Bool=false, options...)
    state = copy(state)
    for act in actions
        diff = execute(domain, state, get_actions(domain)[act.name], act.args;
                       as_diff=true, options...)
        if !as_diff update!(state, diff) end
    end
    # Return either the difference or the final state
    return as_diff ? diff : state
end
