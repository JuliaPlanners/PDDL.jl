"Execute an event if its preconditions hold on a world state."
function execute(evt::Event, state::State,
                 domain::Union{Domain,Nothing}=nothing;
                 as_dist::Bool=false, as_diff::Bool=false)
    # Check whether preconditions hold
    sat, subst = satisfy([evt.precond], state, domain; mode=:all)
    if !sat
        @debug "Precondition $(evt.precond) does not hold."
        return as_diff ? no_effect(as_dist) : state
    end
    # Update state with effects for each matching substitution
    effects = [eval_term(substitute(evt.effect, s), Subst()) for s in subst]
    if as_dist
        # Compute product distribution
        eff_dists = [get_dist(e, state) for e in effects]
        diff = combine(eff_dists...)
    else
        # Accumulate effect diffs
        diff = combine([get_diff(e, state) for e in effects]...)
    end
    # Return either the difference or the updated state
    return as_diff ? diff : update(state, diff)
end

"Execute a set of events on a world state."
function execute(events::Vector{Event}, state::State,
                 domain::Union{Domain,Nothing}=nothing;
                 as_dist::Bool=false, as_diff::Bool=false)
    diffs = [execute(e, state, domain; as_dist=as_dist, as_diff=true)
             for e in events]
    filter!(d -> d != nothing, diffs)
    diff = combine(diffs...)
    # Return either the difference or the updated state
    return as_diff ? diff : update(state, diff)
end
