function transition(domain::GenericDomain, state::GenericState, action::Term;
                    check::Bool=true, fail_mode::Symbol=:error)
    state = execute(domain, state, action; check=check, fail_mode=fail_mode)
    return state
end

"""
    simulate(domain, state, actions; kwargs...)

Returns the state trajectory that results from applying a sequence of `actions`
to an initial `state` in a given `domain`. Keyword arguments specify whether
to `check` if action preconditions hold, the `fail_mode` (`:error` or `:no_op`)
if they do not, and a `callback` function to apply after each step.
"""
function simulate(domain::GenericDomain, state::GenericState,
                  actions::AbstractVector{<:Term};
                  check::Bool=true, fail_mode::Symbol=:error, callback=nothing)
    trajectory = GenericState[state]
    if callback !== nothing callback(domain, state, Const(:start)) end
    for act in actions
        state = transition(domain, state, act; check=check, fail_mode=fail_mode)
        push!(trajectory, state)
        if callback !== nothing callback(domain, state, act) end
    end
    return trajectory
end
