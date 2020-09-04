# PDDL.jl

![GitHub Workflow Status](https://img.shields.io/github/workflow/status/JuliaPlanners/PDDL.jl/CI)
![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/JuliaPlanners/PDDL.jl)
![GitHub](https://img.shields.io/github/license/JuliaPlanners/PDDL.jl?color=lightgrey)

A Julia parser and interpreter for the Planning Domain Definition Language (PDDL). Planners not included.

## Installation

Press `]` at the Julia REPL to enter the package manager, then run:
```
add https://github.com/JuliaPlanners/PDDL.jl.git
```

## Features

- Parsing of PDDL domain and problem files
- Execution of PDDL actions and plans
- Support for the following PDDL requirements:
  - `:strips` - the most restricted functionality
  - `:typing` - (hierarchically) typed objects
  - `:equality` - comparing equality `=` of objects
  - `:quantified-preconditions` - `forall` and `exists`
  - `:disjunctive-preconditions` - `or` predicates
  - `:conditional-effects` - `when` and `forall` effects
  - `:adl` - shorthand for the above 6 requirements
  - `:fluents` - numeric fluents
  - `:derived-predicates` - a.k.a. domain axioms / Horn clauses

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
domain = load_domain("flip-domain.pddl"))
problem = load_problem("flip-problem.pddl"))
```
Actions defined by the domain can be executed to solve the problem:
```julia
state = initialize(problem)
state = execute(pddl"(flip_column c1)", state, domain)
state = execute(pddl"(flip_column c3)", state, domain)
state = execute(pddl"(flip_row r2)", state, domain)
```
We can then check that the problem is successfully solved in the final state:
```julia
@assert satisfy(problem.goal, state, domain)[1] == true
```

More examples can be found in the [`test`](test) directory.
