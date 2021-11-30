## State updates ##

"Update a PDDL state (in-place) with a state difference."
function update!(interpreter::Interpreter,
                 domain::Domain, state::State, diff::Diff)
    error("Not implemented.")
end

function update!(interpreter::Interpreter,
                 domain::Domain, state::State, diff::ConditionalDiff)
    for (cs, d) in zip(diff.conds, diff.diffs)
        if satisfy(domain, state, cs)
            update!(interpreter, domain, state, d)
        end
    end
    return state
end

"Update a PDDL state with a state difference."
function update(interpreter::Interpreter,
                domain::Domain, state::State, diff::Diff)
    return update!(interpreter, domain, copy(state), diff)
end
