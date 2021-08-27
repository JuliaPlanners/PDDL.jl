## State updates ##

"Update a world state (in-place) with a state difference."
function update!(interpreter::ConcreteInterpreter,
                 state::GenericState, diff::Diff)
    setdiff!(state.facts, diff.del)
    union!(state.facts, diff.add)
    for (term, val) in diff.ops
        set_fluent!(state, val, term)
    end
    return state
end

"Update a world state with a state difference."
function update(interpreter::ConcreteInterpreter,
                state::GenericState, diff::Diff)
    return update!(interpreter, copy(state), diff)
end
