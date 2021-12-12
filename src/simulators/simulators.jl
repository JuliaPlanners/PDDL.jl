"Abstract type for PDDL simulators."
abstract type Simulator end

"""
	(sim::Simulator)(domain::Domain, state::State, actions)

Simulates the evolution of a PDDL `domain` as a sequence of `actions` are
executed from an initial `state`.
"""
(sim::Simulator)(domain::Domain, state::State, actions) =
    simulate(sim, domain, state, actions)

"""
	simulate([sim=StateRecorder()], domain::Domain, state::State, actions)

Simulates the evolution of a PDDL `domain` as a sequence of `actions` are
executed from an initial `state`. The type of simulator, `sim`, specifies
what information is collected and returned.

By default, `sim` is a [`StateRecorder`](@ref), which records and returns the
state trajectory.
"""
simulate(sim::Simulator, domain::Domain, state::State, actions) =
	error("Not implemented.")

include("state_recorder.jl")
include("end_state.jl")

simulate(domain::Domain, state::State, actions) =
	simulate(StateRecorder(), domain, state, actions)
