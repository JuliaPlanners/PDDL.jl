# Abstract Interpretation

PDDL.jl supports [abstract interpretation](https://en.wikipedia.org/wiki/Abstract_interpretation) of PDDL domains. This functionality is exposed by the [`abstracted`](@ref) and [`abstractstate`](@ref) functions:

```@docs
abstracted
abstractstate
```

The behavior of the abstract interpreter can be customized by specifying the Julia type used to represent abstract values for a particular fluent or PDDL type:

```@docs
PDDL.AbstractInterpreter
```

Abstract semantics can also be compiled by calling [`compiled`](@ref) on an abstracted domain and state:

```julia
domain, state = abstracted(domain, state)
domain, state = compiled(domain, state)
```

## Abstract Values and Types

Abstract interpretation requires each concrete value to be mapped to an abstract value of a particular type, which represents an (over-approximation) of the set of the possible values reachable after a series of actions have been executed. By default, Boolean values (i.e. predicates) are mapped to the [`BooleanAbs`](@ref) abstraction, while scalar numbers (corresponding to PDDL types like `integer`, `number` and `numeric`) are mapped to the [`IntervalAbs`](@ref) abstraction. Other types of values may use the [`SetAbs`](@ref) abstraction.

```@docs
PDDL.BooleanAbs
PDDL.IntervalAbs
PDDL.SetAbs
```

When introducing a new global datatype using the PDDL.jl extension interfaces, a default abstraction can be associated with the type by defining a new method for [`PDDL.default_abstype`](@ref):

```@docs
PDDL.default_abstype
```

The [`PDDL.@register`](@ref) macro can also be used to register new default abstractions.
