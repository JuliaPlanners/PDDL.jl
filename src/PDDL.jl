module PDDL

using Base: @kwdef
using AutoHashEquals
using Julog
using ValSplit
using DocStringExtensions

# Logical formulae and terms
export Term, Compound, Var, Const, Clause
# Abstract data types
export Domain, Problem, State, Action
# Generic concrete data types
export GenericDomain, GenericProblem, GenericState, GenericAction
# Interface methods
export satisfy, satisfiers, evaluate
export initstate, goalstate, transition, transition!
export available, execute, execute!, relevant, regress, regress!
# Parsing and writing
export parse_domain, parse_problem, parse_pddl, @pddl, @pddl_str
export write_domain, write_problem, write_pddl
export load_domain, load_problem
export save_domain, save_problem
# Simulators
export Simulator, EndStateSimulator, StateRecorder
# Abstract interpretation
export abstracted, abstractstate
export AbstractedDomain
# Domain compilation
export compiled, compilestate
export CompiledDomain, CompiledAction, CompiledState
# Domain and action grounding
export ground, groundargs, groundactions, groundaxioms
export GroundDomain, GroundAction, GroundActionGroup
# Domain and method caching
export CachedDomain
# Extension interfaces
export attach!, register!, @register, @pddltheory
# Analysis tools
export infer_affected_fluents, infer_static_fluents, infer_relevant_fluents
export infer_axiom_hierarchy
# Utilities
export effect_diff, precond_diff

# PDDL requirement definitions and dependencies
include("requirements.jl")
# Abstract interface for PDDL-based planners and applications
include("interface/interface.jl")
# Generic concrete representations of PDDL types
include("generic/generic.jl")
# Parser for PDDL files and formulae
include("parser/parser.jl")
# Writer for PDDL files and formulae
include("writer/writer.jl")

using .Parser, .Writer

# Simulators for executing action sequences and recording outputs
include("simulators/simulators.jl")
# Built-in functions and operators recognized by interpreters / compilers
include("builtins.jl")
# Methods for extending built-in functions and operators
include("extensions.jl")
# Theories for fluents with non-standard data types (e.g. sets, arrays)
include("theories/theories.jl")
# Abstractions for fluents of various types
include("abstractions/abstractions.jl")
# Interpreter-based interface implementation
include("interpreter/interpreter.jl")
# Compiler-based interface implementations
include("compiler/compiler.jl")
# Domain and action grounding
include("grounding/grounding.jl")
# Caching for interface methods
include("caching/caching.jl")
# Tools for analyzing domains
include("analysis/analysis.jl")

end # module
