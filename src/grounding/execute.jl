function execute(domain::GroundDomain, state::State, term::Term, options...)
    if term.name == get_name(no_op) return state end
    return execute!(domain, copy(state), term; options...)
end

function execute(domain::GroundDomain, state::State,
                 action::GroundActionGroup, args; options...)
    return execute!(domain, copy(state), action, args; options...)
end

function execute(domain::GroundDomain, state::State,
                 action::GroundAction; options...)
    return execute!(domain, copy(state), action; options...)
end

function execute!(domain::GroundDomain, state::State, term::Term; options...)
   if term.name == get_name(no_op) return state end
   if (term isa Const) term = Compound(term.name, []) end
   action = domain.actions[term.name].actions[term]
   return execute!(domain, state, action; options...)
end

function execute!(domain::GroundDomain, state::State,
                  group::GroundActionGroup, args; options...)
   term = Compound(group.name, args)
   return execute!(domain, state, group.actions[term]; options...)
end

function execute!(domain::GroundDomain, state::State,
                  action::GroundAction; check::Bool=true)
    # Check whether preconditions hold
    if check && !available(domain, state, action)
        error("Precondition $(get_precond(action)) does not hold.")
    end
    # Update state with diff
    return update!(domain, state, action.effect)
end
