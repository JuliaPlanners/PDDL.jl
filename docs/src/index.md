# PDDL.jl

A extensible and performant interface for symbolic planning domains specified in the Planning Domain Definition Language (PDDL), with support for PDDL parsing, interpretation, and compilation.

## Features

- Parsing and writing of PDDL domain and problem files
- A high-level symbolic planning API for use by algorithms and applications
- Execution of PDDL actions and plans
- Abstract interpretation of PDDL semantics
- Domain grounding and compilation for increased performance
- Semantic extensibility through modular theories

PDDL.jl does not include any planning algorithms. Rather, it provides an interface so that planners for PDDL domains can easily be written, as in [SymbolicPlanners.jl](https://github.com/JuliaPlanners/SymbolicPlanners.jl).

## Tutorials

Learn how to install and use PDDL.jl by following these tutorials:

```@contents
Pages = [
    "tutorials/getting_started.md",
    "tutorials/writing_planners.md",
    "tutorials/speeding_up.md",
    "tutorials/extending.md"
]
Depth = 1
```

## Architecture and Interface

Learn about the architecture of PDDL.jl, its high-level interface for symbolic planning, and the built-in implementations of this interface:

```@contents
Pages = [
    "ref/overview.md",
    "ref/datatypes.md",
    "ref/interface.md",
    "ref/parser_writer.md",
    "ref/interpreter.md",
    "ref/compiler.md",
    "ref/absint.md",
    "ref/utilities.md"
]
Depth = 1
```
