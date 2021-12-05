## State updates ##

function update!(interpreter::ConcreteInterpreter,
                 domain::Domain, state::GenericState, diff::GenericDiff)
    setdiff!(state.facts, diff.del)
    union!(state.facts, diff.add)
    vals = [evaluate(domain, state, v) for v in values(diff.ops)]
    for (term, val) in zip(keys(diff.ops), vals)
        set_fluent!(state, val, term)
    end
    return state
end
