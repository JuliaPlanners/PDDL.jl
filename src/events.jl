# Functions for handling and triggering events

"""
    trigger(event::Event, state, domain=nothing; kwargs...)
    trigger(events::Vector{Event}, state, domain=nothing; kwargs...)

Trigger an `event` or list of `events` if their preconditions hold in the given
`state` and `domain`. See [`execute`](@ref) for keyword arguments.
"""
function trigger(event::Event, state::State,
                 domain::Union{Domain,Nothing}=nothing;
                 as_dist::Bool=false, as_diff::Bool=false)
    # Check whether preconditions hold
    sat, subst = satisfy([event.precond], state, domain; mode=:all)
    if !sat
        @debug "Precondition $(event.precond) does not hold."
        return as_diff ? no_effect(as_dist) : state
    end
    # Update state with effects for each matching substitution
    effects = [substitute(event.effect, s) for s in subst]
    if as_dist
        # Compute product distribution
        eff_dists = [effect_dist(e, state) for e in effects]
        diff = combine(eff_dists...)
    else
        # Accumulate effect diffs
        diff = combine([effect_diff(e, state) for e in effects]...)
    end
    # Return either the difference or the updated state
    return as_diff ? diff : update(state, diff)
end

function trigger(events::Vector{Event}, state::State,
                 domain::Union{Domain,Nothing}=nothing;
                 as_dist::Bool=false, as_diff::Bool=false)
    if length(events) == 0
        diff = as_dist ? DiffDist() : Diff()
    else
        diffs = [trigger(e, state, domain; as_dist=as_dist, as_diff=true)
                 for e in events]
        filter!(d -> !isnothing(d), diffs)
        diff = combine(diffs...)
    end
    # Return either the difference or the updated state
    return as_diff ? diff : update(state, diff)
end
