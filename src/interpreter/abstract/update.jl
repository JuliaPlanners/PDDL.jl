## State updates ##

function update!(interpreter::AbstractInterpreter,
                 domain::Domain, state::GenericState, diff::GenericDiff)
    if interpreter.autowiden
        return widen!(interpreter, domain, state, diff)
    end
    union!(state.facts, negate.(diff.del))
    setdiff!(state.facts, diff.del)
    union!(state.facts, diff.add)
    setdiff!(state.facts, negate.(diff.del))
    vals = [evaluate(domain, state, v) for v in values(diff.ops)]
    for (term, val) in zip(keys(diff.ops), vals)
        set_fluent!(state, val, term)
    end
    return state
end

"Widen a state (in-place) with a state difference."
function widen!(interpreter::AbstractInterpreter,
                domain::Domain, state::GenericState, diff::GenericDiff)
    union!(state.facts, negate.(diff.del))
    if !haskey(interpreter.type_abstractions, :boolean)
        for term in diff.del
            is_abstracted(term, domain) && continue
            delete!(state.facts, term)
        end
    end
    union!(state.facts, diff.add)
    if !haskey(interpreter.type_abstractions, :boolean)
        for term in diff.add
            is_abstracted(term, domain) && continue
            delete!(state.facts, negate(term))
        end
    end
    vals = [evaluate(domain, state, v) for v in values(diff.ops)]
    for (term, val) in zip(keys(diff.ops), vals)
        if is_abstracted(term, domain)
            widened = widen(get_fluent(state, term), val)
            set_fluent!(state, widened, term)
        else
            set_fluent!(state, val, term)
        end
    end
    return state
end

"Widen a state with a state difference."
function widen(interpreter::AbstractInterpreter,
               state::GenericState, diff::Diff)
    return widen!(interpreter, copy(state), diff)
end

"Widen a state (in-place) with another state."
function widen!(domain::AbstractedDomain,
                s1::GenericState, s2::GenericState)
    union!(s1.facts, s2.facts)
    if isempty(get_functions(domain)) return s1 end
    for (term, val) in get_fluents(s2)
        if is_pred(term, domain) continue end
        widened = widen(get_fluent(s1, term), val)
        set_fluent!(s1, widened, term)
    end
    return s1
end

"Widen a state with another state."
widen(domain::AbstractedDomain, s1::GenericState, s2::GenericState) =
    widen!(domain.interpreter, copy(s1), s2)
