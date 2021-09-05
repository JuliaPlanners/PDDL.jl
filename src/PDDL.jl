module PDDL

using Base: @kwdef
using Julog
using AutoHashEquals

# Logical formulae and terms
export Term, Compound, Var, Const, Clause
# Abstract data types
export Domain, Problem, State, Action
# Generic concrete data types
export GenericDomain, GenericProblem, GenericState, GenericAction
# Interface methods
export satisfy, satisfiers, evaluate
export initstate, goalstate, transition, simulate
export available, execute, relevant, regress
# Parsing and writing
export parse_domain, parse_problem, parse_pddl, @pddl, @pddl_str
export write_domain, write_problem, write_pddl
export load_domain, load_problem
export save_domain, save_problem
# Abstract interpretation
export abstracted, abstractstate, lub, glb, widen, widen!
export AbstractedDomain
# Domain compilation
export compiled, compilestate
export CompiledDomain, CompiledAction, CompiledState
# Extension interfaces
export attach!, register!
# Analysis tools
export DependencyGraph, dependency_graph
# Utilities
# export get_static_predicates, get_static_functions
export find_matches, effect_diff, precond_diff

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
# Built-in functions and operators recognized by interpreters / compilers
include("builtins.jl")
# Methods for extending built-in functions and operators
include("extensions.jl")
# Abstractions for fluents of various types
include("abstractions/abstractions.jl")
# Interpreter-based interface implementation
include("interpreter/interpreter.jl")
# Compiler-based interface implementations
include("compiler/compiler.jl")
# Tools for analyzing domains
include("analysis/analysis.jl")
# Various utilities
include("utils.jl")

using .Parser, .Writer

end # module
