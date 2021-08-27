## State updates ##

"Update a state (in-place) with a state difference."
function update!(interpreter::AbstractInterpreter,
                 state::GenericState, diff::Diff)
    if interpreter.autowiden return widen!(interpreter, state, diff) end
    union!(state.facts, negate.(diff.del))
    setdiff!(state.facts, diff.del)
    union!(state.facts, diff.add)
    setdiff!(state.facts, negate.(diff.del))
    for (term, val) in diff.ops
        set_fluent!(state, val, term)
    end
    return state
end

"Update a state with a state difference."
function update(interpreter::AbstractInterpreter,
                state::GenericState, diff::Diff)
    return update!(interpreter, copy(state), diff)
end

"Widen a state (in-place) with a state difference."
function widen!(interpreter::AbstractInterpreter,
                state::GenericState, diff::Diff)
    union!(state.facts, negate.(diff.del))
    union!(state.facts, diff.add)
    for (term, val) in diff.ops
        widened = widen(get_fluent(state, term), val)
        set_fluent!(state, widened, term)
    end
    return state
end

"Widen a state with a state difference."
function widen(interpreter::AbstractInterpreter,
               state::GenericState, diff::Diff)
    return widen!(interpreter, copy(state), diff)
end
