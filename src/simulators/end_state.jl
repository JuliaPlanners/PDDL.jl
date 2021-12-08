"Simulator that returns end state of simulation."
@kwdef struct EndStateSimulator <: Simulator
    max_steps::Union{Int,Nothing} = nothing
end

function simulate(sim::EndStateSimulator, domain::Domain, state::State, actions)
    state = copy(state)
    for (t, act) in enumerate(actions)
        state = transition!(domain, state, act)
        sim.max_steps !== nothing && t >= sim.max_steps && break
    end
    return state
end
