"""
	StateRecorder(max_steps::Union{Int,Nothing} = nothing)

Simulator that records the state trajectory, including the start state.
"""
@kwdef struct StateRecorder <: Simulator
    max_steps::Union{Int,Nothing} = nothing
end

function simulate(sim::StateRecorder, domain::Domain, state::State, actions)
    trajectory = [state]
	for (t, act) in enumerate(actions)
        state = transition(domain, state, act)
		push!(trajectory, state)
		sim.max_steps !== nothing && t >= sim.max_steps && break
    end
    return trajectory
end
