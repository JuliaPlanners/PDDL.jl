# Functions for handling and triggering events

function trigger(domain::GenericDomain, state::GenericState,
                 event::GenericEvent; as_diff::Bool=false)
    # Check whether preconditions hold
    subst = satisfiers(domain, state, event.precond)
    if length(subst) == 0
        @debug "Precondition $(event.precond) does not hold."
        return as_diff ? no_effect() : state
    end
    # Update state with effects for each matching substitution
    diff = combine((effect_diff(substitute(event.effect, s), state)
                    for s in subst)...)
    # Return either the difference or the updated state
    return as_diff ? diff : update(state, diff)
end

function trigger(domain::GenericDomain, state::GenericState,
                 events::AbstractVector{GenericEvent}; as_diff::Bool=false)
    if length(events) == 0
        diff = no_effect()
    else
        diffs = [trigger(domain, state, e; as_diff=true) for e in events]
        filter!(d -> !isnothing(d), diffs)
        diff = combine(diffs...)
    end
    # Return either the difference or the updated state
    return as_diff ? diff : update(state, diff)
end
