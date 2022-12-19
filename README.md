# PDDL.jl

[![Documentation (Stable)](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliaplanners.github.io/PDDL.jl/stable)
[![Documentation (Latest)](https://img.shields.io/badge/docs-latest-blue.svg)](https://juliaplanners.github.io/PDDL.jl/dev)
![GitHub Workflow Status](https://img.shields.io/github/workflow/status/JuliaPlanners/PDDL.jl/CI?branch=master)
![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/JuliaPlanners/PDDL.jl)
![GitHub](https://img.shields.io/github/license/JuliaPlanners/PDDL.jl?color=lightgrey)

A Julia parser, interpreter, and compiler interface for the Planning Domain Definition Language (PDDL).

Planners not included, but see [`SymbolicPlanners.jl`](https://github.com/JuliaPlanners/SymbolicPlanners.jl).

If you use this software, please cite:

> T. Zhi-Xuan, [“PDDL.jl: An Extensible Interpreter and Compiler Interface for Fast and Flexible AI Planning”](https://dspace.mit.edu/handle/1721.1/143179), MS Thesis, Massachusetts Institute of Technology, 2022.

## Installation

Press `]` at the Julia REPL to enter the package manager, then run:
```
add PDDL
```

For the latest development version, run:
```
add https://github.com/JuliaPlanners/PDDL.jl.git
```

## Features

- Parsing and writing of PDDL domain and problem files
- A high-level symbolic planning API
- Execution of PDDL actions and plans
- Abstract interpretation of PDDL semantics
- Domain grounding and/or compilation for increased performance
- Support for the following PDDL requirements:
  - `:strips` - the most restricted functionality
  - `:typing` - (hierarchically) typed objects
  - `:equality` - comparing equality `=` of objects
  - `:quantified-preconditions` - `forall` and `exists`
  - `:disjunctive-preconditions` - `or` predicates
  - `:conditional-effects` - `when` and `forall` effects
  - `:adl` - shorthand for the above 6 requirements
  - `:constants` - domain constants
  - `:fluents` - numeric fluents
  - `:derived-predicates` - a.k.a. domain axioms

`PDDL.jl` does not include any planning algorithms. Rather, it aims to provide an
interface so that planners for PDDL domains can easily be written in Julia, as
in [`SymbolicPlanners.jl`](https://github.com/JuliaPlanners/SymbolicPlanners.jl).

## Example

`PDDL.jl` can be used to parse domains and planning problems written in PDDL.
For example, the following file describes a world of square tiles which are either
white or black, arranged in a grid. To change the color of the tiles one can flip
either a row of tiles or a column of tiles.
```clojure
;; Grid flipping domain with conditional effects and universal quantifiers
(define (domain flip)
  (:requirements :adl :typing)
  (:types row column)
  (:predicates (white ?r - row ?c - column))
  (:action flip_row
    :parameters (?r - row)
    :effect (forall (?c - column)
                    (and (when (white ?r ?c) (not (white ?r ?c)))
                         (when (not (white ?r ?c)) (white ?r ?c))))
  )
  (:action flip_column
    :parameters (?c - column)
    :effect (forall (?r - row)
                    (and (when (white ?r ?c) (not (white ?r ?c)))
                         (when (not (white ?r ?c)) (white ?r ?c))))
  )
)
```
A corresponding problem in this domain might be to make all the tiles white,
when the initial state is an alternating pattern of black and white tiles in a 3x3 grid:
```clojure
;; Grid flipping problem
(define (problem flip-problem)
  (:domain flip)
  (:objects r1 r2 r3 - row c1 c2 c3 - column)
  (:init (white r1 c2)
         (white r2 c1)
         (white r2 c3)
         (white r3 c2))
  (:goal (forall (?r - row ?c - column) (white ?r ?c)))
)
```

With `PDDL.jl`, we can parse each of these files into Julia constructs:
```julia
domain = load_domain("flip-domain.pddl")
problem = load_problem("flip-problem.pddl")
```
Actions defined by the domain can be executed to solve the problem:
```julia
state = initstate(domain, problem)
state = execute(domain, state, pddl"(flip_column c1)")
state = execute(domain, state, pddl"(flip_column c3)")
state = execute(domain, state, pddl"(flip_row r2)")
```
We can then check that the problem is successfully solved in the final state:
```julia
@assert satisfy(domain, state, problem.goal) == true
```

More examples can be found in the [`test`](test) directory. Documentation can be found [here](https://juliaplanners.github.io/PDDL.jl/stable).

## Interface

PDDL.jl exposes a high-level interface for interacting with planning domains and problems, which can be used to implement planning algorithms and other downstream applications. Full documentation of interface methods can be found [here](https://juliaplanners.github.io/PDDL.jl/stable/ref/interface/#Interface-Functions). A summary is provided below:

- `satisfy` checks whether a logical formula is satisfied (or satisfiable) in a PDDL state.
- `satisfiers` returns all satisfying substitutions to free variables in a logical formula.
- `evaluate` returns the value of a functional or logical expression within the context of a state.
- `initstate` constructs an initial state from a PDDL domain and problem.
- `goalstate` constructs a (partial) goal state from a PDDL domain and problem
- `transition` returns the successor to a state after applying an action or set of actions.
- `execute` applies an action to a state, returning the resulting state.
- `regress` computes the pre-image of an action with respect to a state.
- `available` checks whether an action can be executed in a state.
  - If no action is specified, it returns the list of available actions.
- `relevant` checks whether an action can lead to a state.
  - If no action is specified, it returns the list of relevant actions.
