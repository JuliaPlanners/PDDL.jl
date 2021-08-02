# Functions for handling and triggering events

function trigger(domain::GenericDomain, state::GenericState,
                 event::GenericEvent, as_dist::Bool=false, as_diff::Bool=false)
    # Check whether preconditions hold
    subst = satisfiers(domain, state, event.precond)
    if length(subst) == 0
        @debug "Precondition $(event.precond) does not hold."
        return as_diff ? no_effect(as_dist) : state
    end
    # Update state with effects for each matching substitution
    effects = (substitute(event.effect, s) for s in subst)
    if as_dist
        # Compute product distribution
        eff_dists = (effect_dist(e, state) for e in effects)
        diff = combine(eff_dists...)
    else
        # Accumulate effect diffs
        diff = combine((effect_diff(e, state) for e in effects)...)
    end
    # Return either the difference or the updated state
    return as_diff ? diff : update(state, diff)
end

function trigger(domain::GenericDomain, state::GenericState,
                 events::AbstractVector{GenericEvent};
                 as_dist::Bool=false, as_diff::Bool=false)
    if length(events) == 0
        diff = as_dist ? DiffDist() : Diff()
    else
        diffs = [trigger(domain, state, e; as_dist=as_dist, as_diff=true)
                 for e in events]
        filter!(d -> !isnothing(d), diffs)
        diff = combine(diffs...)
    end
    # Return either the difference or the updated state
    return as_diff ? diff : update(state, diff)
end
