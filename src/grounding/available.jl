function available(domain::GroundDomain, state::State)
    iters = ((t for (t, a) in group.actions if available(domain, state, a))
             for (_, group) in domain.actions)
    return Iterators.flatten(iters)
end

function available(domain::GroundDomain, state::State,
                   group::GroundActionGroup, args)
    term = Compound(group.name, args)
    return available(domain, state, group.actions[term])
end

function available(domain::GroundDomain, state::State, term::Term)
    if term.name == get_name(no_op) return true end
    if (term isa Const) term = Compound(term.name, []) end
    action = domain.actions[term.name].actions[term]
    return available(domain, state, action)
end

function available(domain::GroundDomain, state::State, action::GroundAction)
    return satisfy(domain, state, action.preconds)
end
