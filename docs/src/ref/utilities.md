# Utilities

PDDL.jl provides a variety of utilities for working with and manipulating planning domains, including plan simulation, domain grounding, and tools for domain and formula analysis.

## Simulation

It is often useful to simulate the results of applying a series of actions to an initial state. PDDL.jl supports this with the [`Simulator`](@ref) datatype, and the associated [`PDDL.simulate`](@ref) method. 

```@docs
Simulator
PDDL.simulate
```

The following types of [`Simulator`](@ref) are provided, depending on what results are desired:

```@docs
StateRecorder
EndStateSimulator
```

## Grounding

Many planning algorithms and search heuristics benefit from grounding of actions and axioms with respect to the fixed set of objects in the initial state. PDDL.jl provides the [`GroundAction`](@ref) datatype to represent grounded actions, as well as the [`groundactions`](@ref) and [`groundaxioms`](@ref) functions to convert lifted [`Action`](@ref)s and axiom `Clause`s into lists of grounded actions:

```@docs
GroundAction
groundactions
groundaxioms
```

PDDL.jl also provides the [`ground`](@ref) function, which can be used to ground specific actions:

```@docs
ground(::Domain, ::State, ::Action, ::Any)
ground(::Domain, ::State, ::GenericAction)
```

The [`ground`](@ref) function can also be used to ground an entire domain with respect to an initial state, returning a [`GroundDomain`](@ref) that can be used in place of the original domain:

```@docs
ground(::Domain, ::State)
GroundDomain
```

## Analysis

Static analysis of domains, actions, and formulae is often used in a variety of downstream tasks such as grounding, compilation, and relevance pruning. PDDL.jl provides a suite of analysis tools that can be helpful for these purposes.

### Domain Analysis

Certain analyses are performed on planning domains as whole (e.g. inferring the set of static fluents). The following domain-level analyses are provided by PDDL.jl:

```@docs
infer_static_fluents
infer_affected_fluents
infer_relevant_fluents
infer_axiom_hierarchy
```

An associated set of (un-exported) utility functions are provided:

```@docs
PDDL.is_static
PDDL.is_affected
PDDL.simplify_statics
PDDL.substitute_axioms
```

### Formula Analysis

PDDL.jl also provides a list of utilities for analyzing formula properties (some of which may be specific to the domain they are defined in). Note that these utilities are not exported.

The following utilities determine top-level properties of a [`Term`](@ref).

```@docs
PDDL.is_pred
PDDL.is_derived
PDDL.is_global_pred
PDDL.is_func
PDDL.is_global_func
PDDL.is_attached_func
PDDL.is_external_func
PDDL.is_fluent
PDDL.is_literal
PDDL.is_logical_op
PDDL.is_negation
PDDL.is_quantifier
PDDL.is_type
PDDL.has_subtypes
```

The following utilities determine properties of a [`Term`](@ref) or any of its nested subterms.

```@docs
PDDL.has_name
PDDL.has_pred
PDDL.has_derived
PDDL.has_global_pred
PDDL.has_func
PDDL.has_global_func
PDDL.has_attached_func
PDDL.has_fluent
PDDL.has_logical_op
PDDL.has_negation
PDDL.has_quantifier
PDDL.has_type
```

The [`PDDL.constituents`](@ref) function can be used to decompose a formula into a list of its constituent fluent terms:

```@docs
PDDL.constituents
```
