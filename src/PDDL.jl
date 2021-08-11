module PDDL

using Base: @kwdef
using Julog
using AutoHashEquals

export Domain, Problem, State, Action, Event
export GenericDomain, GenericProblem, GenericState, GenericAction, GenericEvent
export Term, Compound, Var, Const
export parse_domain, parse_problem, parse_pddl, @pddl, @pddl_str
export write_domain, write_problem, write_pddl
export load_domain, load_problem
export save_domain, save_problem
export get_static_predicates, get_static_functions
export satisfy, satisfiers, evaluate, find_matches
export initstate, goalstate, transition, simulate
export get_preconditions, get_effect
export effect_diff, precond_diff, update!, update
export available, relevant, execute, regress, trigger
export use_available_action_cache!, use_relevant_action_cache!
export clear_available_action_cache!, clear_relevant_action_cache!

# PDDL requirement definitions and dependencies
include("requirements.jl")
# Abstract interface for PDDL-based planners and applications
include("interface/interface.jl")
# Generic concrete representations of PDDL types
include("generic/generic.jl")
# Parser for PDDL files
include("parser/parser.jl")
# Writer for PDDL files
include("writer/writer.jl")
# Interpreter-based interface implementation
include("interpreter/interpreter.jl")
# Compiler-based interface implementations
include("compiler/compiler.jl")
# Various utilities
include("utils.jl")

using .Parser, .Writer

end # module
