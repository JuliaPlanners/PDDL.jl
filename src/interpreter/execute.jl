function execute(interpreter::Interpreter,
                 domain::Domain, state::State, action::Action, args;
                 check::Bool=true, fail_mode::Symbol=:error)
    # Check whether references resolve and preconditions hold
    if check && !available(interpreter, domain, state, action, args)
        if fail_mode == :no_op return state end
        error("Precondition $(write_pddl(get_precond(action))) does not hold.")
    end
    return execute!(interpreter, domain, copy(state), action, args; check=false)
end

function execute(interpreter::Interpreter,
                 domain::Domain, state::State, action::Term; options...)
    if action.name == get_name(no_op) return state end
    return execute(interpreter, domain, state, get_action(domain, action.name),
                   action.args; options...)
end

function execute!(interpreter::Interpreter,
                  domain::Domain, state::State, action::Action, args;
                  check::Bool=true, fail_mode::Symbol=:error)
    # Check whether references resolve and preconditions hold
    if check && !available(interpreter, domain, state, action, args)
        if fail_mode == :no_op return state end
        error("Precondition $(write_pddl(get_precond(action))) does not hold.")
    end
    # Substitute arguments and preconditions
    subst = Subst(var => val for (var, val) in zip(get_argvars(action), args))
    effect = substitute(get_effect(action), subst)
    # Compute effect as a state diffference
    diff = effect_diff(domain, state, effect)
    return update!(interpreter, domain, state, diff)
end

function execute!(interpreter::Interpreter,
                  domain::Domain, state::State, action::Term; options...)
    if action.name == get_name(no_op) return state end
    return execute!(interpreter, domain, state, get_action(domain, action.name),
                    action.args; options...)
end
