## State updates ##

function update!(interpreter::Interpreter,
                 domain::Domain, state::State, diff::Diff)
    error("Not implemented.")
end

function update!(interpreter::Interpreter,
                 domain::Domain, state::State, diff::ConditionalDiff)
    if isempty(diff.diffs) return state end
    combined = empty(diff.diffs[1])
    for (cs, d) in zip(diff.conds, diff.diffs)
        satisfy(domain, state, cs) && combine!(combined, d)
    end
    return update!(interpreter, domain, state, combined)
end

function update(interpreter::Interpreter,
                domain::Domain, state::State, diff::Diff)
    return update!(interpreter, domain, copy(state), diff)
end
