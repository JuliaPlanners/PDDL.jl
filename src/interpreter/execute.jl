function execute(domain::GenericDomain, state::GenericState,
                 act::GenericAction, args; as_diff::Bool=false,
                 check::Bool=true, fail_mode::Symbol=:error)
    # Check whether references resolve and preconditions hold
    if check && !available(domain, state, act, args)
        if fail_mode == :no_op return as_diff ? no_effect() : state end
        error("Precondition $(act.precond) does not hold.") # Error by default
    end
    # Substitute arguments and preconditions
    # TODO : Check for non-ground terms outside of quantified formulae
    subst = Subst(var => val for (var, val) in zip(act.args, args))
    effect = substitute(act.effect, subst)
    # Compute effect as a state diffference
    diff = effect_diff(domain, state, effect)
    # Return either the difference or the updated state
    return as_diff ? diff : update(state, diff)
end

function execute(domain::GenericDomain, state::GenericState, act::Term; options...)
    if act.name in keys(domain.actions)
        act_def, act_args = domain.actions[act.name], get_args(act)
        execute(domain, state, act_def, act_args; options...)
    elseif act.name == Symbol("--")
        execute(domain, state, no_op, Term[]; options...)
    else
        error("Unknown action: $act")
    end
end

function execute(domain::GenericDomain, state::GenericState,
                 actions::AbstractVector{<:Term};
                 as_diff::Bool=false, options...)
    state = copy(state)
    for act in actions
        diff = execute(domain, state, domain.actions[act.name], act.args;
                       as_diff=true, options...)
        if !as_diff update!(state, diff) end
    end
    # Return either the difference or the final state
    return as_diff ? diff : state
end
