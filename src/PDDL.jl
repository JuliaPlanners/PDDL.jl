module PDDL

using Base: @kwdef
using Julog

export Domain, Problem, State, Action, Event
export GenericDomain, GenericProblem, GenericState, GenericAction, GenericEvent
export Term, Compound, Var, Const
export parse_domain, parse_problem, parse_pddl, @pddl, @pddl_str
export write_domain, write_problem, write_pddl
export load_domain, load_problem, preprocess
export save_domain, save_problem
export get_static_predicates, get_static_functions
export satisfy, satisfiers, evaluate, find_matches
export initstate, goalstate, transition, simulate
export get_preconditions, get_effect
export effect_diff, precond_diff, update!, update
export available, relevant, execute, regress, trigger
export use_available_action_cache!, use_relevant_action_cache!
export clear_available_action_cache!, clear_relevant_action_cache!

include("requirements.jl")
include("interface.jl")
include("structs.jl")
include("parser.jl")
include("writer.jl")

using .Parser, .Writer

include("utils.jl")
include("core.jl")
include("preprocess.jl")
include("states.jl")
include("effects.jl")
include("actions.jl")
include("events.jl")

end # module
