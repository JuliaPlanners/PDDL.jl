# Extension Interfaces

PDDL.jl provides a set of extension interfaces for adding new global predicates, functions, and types. Extensions can be added on a per-predicate or per-function basis, or by registering *theories* that provide a class of related functionality.

## Built-in Types, Predicates and Functions

PDDL.jl stores mappings from (global) names to their implementations by making use of [value-based dispatch](https://github.com/ztangent/ValSplit.jl). These mappings are stored by defining methods for the following functions:

```@docs
PDDL.datatype_def
PDDL.predicate_def
PDDL.function_def
PDDL.modifier_def
```

These mappings can also be accessed in dictionary form with the following utility functions:

```@docs
PDDL.global_datatypes()
PDDL.global_predicates()
PDDL.global_functions()
PDDL.global_modifiers()
```

### Datatypes

By default, PDDL.jl supports fluents with Boolean and numeric values. These correspond to the PDDL datatypes named `boolean`, `integer`, `number` and `numeric`, and are implemented in Julia with the `Bool`, `Int` and `Float64` types:

```julia
PDDL.datatype_def(::Val{:boolean}) = (type=Bool, default=false)
PDDL.datatype_def(::Val{:integer}) = (type=Int, default=0)
PDDL.datatype_def(::Val{:number}) = (type=Float64, default=1.0)
PDDL.datatype_def(::Val{:numeric}) = (type=Float64, default=1.0)
```

When declaring a function in a PDDL domain, it is possible to denote its (output) type as one of the aforementioned types. For example, the `distance` between two cities might be declared to have a `number` type:

```pddl
(distance ?c1 - city ?c2 - city) - number
```

### Predicates and Functions

PDDL.jl also supports built-in predicates and functions for comparisons and arithmetic operations. Since these functions can be used in any PDDL domain, they are called *global* functions. Global predicates and functions are implemented by mapping them to Julia functions:

```julia
# Built-in predicates
PDDL.predicate_def(::Val{:(==)}) = PDDL.equiv
PDDL.predicate_def(::Val{:<=}) = <=
PDDL.predicate_def(::Val{:>=}) = >=
PDDL.predicate_def(::Val{:<}) = <
PDDL.predicate_def(::Val{:>}) = >

# Built-in functions
PDDL.function_def(::Val{:+}) = +
PDDL.function_def(::Val{:-}) = -
PDDL.function_def(::Val{:*}) = *
PDDL.function_def(::Val{:/}) = /
```

### Modifiers

Finally, PDDL.jl supports modifier expressions such as `(increase fluent val)`, which modifies the current value of `fluent` by `val`, setting the new value of `fluent` to the modified `value`. Like global functions, modifiers are implemented by mapping their names to corresponding Julia functions:

```julia
PDDL.modifier_def(::Val{:increase}) = :+
PDDL.modifier_def(::Val{:decrease}) = :-
PDDL.modifier_def(::Val{Symbol("scale-up")}) = :*
PDDL.modifier_def(::Val{Symbol("scale-down")}) = :/
```

## Adding Types, Predicates and Functions

To add a new global datatype, predicate, function, or modifier to PDDL, it is enough to define a new method of [`PDDL.datatype_def`](@ref), [`PDDL.predicate_def`](@ref), [`PDDL.function_def`](@ref), or [`PDDL.modifier_def`](@ref) respectively. Alternatively, one can use the [`@register`](@ref) macro to register new implementations at compile-time:

```@docs
PDDL.@register
```

In scripting contexts, run-time registration and de-registration can be achieved using [`PDDL.register!`](@ref) and [`PDDL.deregister!`](@ref):

```@docs
PDDL.register!
PDDL.deregister!
```

## Defining and Registering Theories

Similar to [Satisfiability Modulo Theories (SMT) solvers](https://en.wikipedia.org/wiki/Satisfiability_modulo_theories), PDDL.jl provides support for [*planning* modulo theories](https://dl.acm.org/doi/10.5555/3038546.3038555). By registering a new theory, developers can extend the semantics of PDDL to handle new mathematical objects such as sets, arrays, and tuples.

A new theory can be implemented by writing a (sub)module annotated with the [`@pddltheory`](@ref) macro:

```@docs
@pddltheory
```

For example, a theory for how to handle sets of PDDL objects can be written as follows (adapting the example by [Gregory et al (2012)](https://dl.acm.org/doi/10.5555/3038546.3038555)):

```julia
@pddltheory module Sets

using PDDL
using PDDL: SetAbs

construct_set(xs::Symbol...) = Set{Symbol}(xs)
empty_set() = Set{Symbol}()
cardinality(s::Set) = length(s)
member(s::Set, x) = in(x, s)
subset(x::Set, y::Set) = issubset(x, y)
union(x::Set, y::Set) = Base.union(x, y)
intersect(x::Set, y::Set) = Base.intersect(x, y)
difference(x::Set, y::Set) = setdiff(x, y)
add_element(s::Set, x) = push!(copy(s), x)
rem_element(s::Set, x) = pop!(copy(s), x)

set_to_term(s::Set) = isempty(s) ? Const(Symbol("(empty-set)")) :
    Compound(Symbol("construct-set"), PDDL.val_to_term.(collect(s)))

const DATATYPES = Dict(
    "set" => (type=Set{Symbol}, default=Set{Symbol}())
)

const ABSTRACTIONS = Dict(
    "set" => SetAbs{Set{Symbol}}
)

const CONVERTERS = Dict(
    "set" => set_to_term
)

const PREDICATES = Dict(
    "member" => member,
    "subset" => subset
)

const FUNCTIONS = Dict(
    "construct-set" => construct_set,
    "empty-set" => empty_set,
    "cardinality" => cardinality,
    "union" => union,
    "intersect" => intersect,
    "difference" => difference,
    "add-element" => add_element,
    "rem-element" => rem_element
)

end
```

This theory introduces a new PDDL type called `set`, implemented as the Julia datatype `Set{Symbol}`. Sets can be modified with functions such as `union` or `add-element`, and can also serve as arguments to predicates like `subset`. The default abstraction for a set is specified to be a [`SetAbs`](@ref), which means that the abstract interpreter will use a set of sets to represent the abstract value of a set-valued variable.

After defining a new theory, we can *register* it by calling the `@register` macro for that module, and make use of the new functionality in PDDL domains and problems:

```julia
Sets.@register()

domain = pddl"""
(define (domain storytellers)
  (:requirements :typing :fluents)
  (:types storyteller audience story)
  (:functions (known ?t - storyteller) - set
              (heard ?a - audience) - set
              (story-set) - set
  )
  (:action entertain
    :parameters (?t - storyteller ?a - audience)
    :precondition (true)
    :effect ((assign (heard ?a) (union (heard ?a) (known ?t))))
  )
)
"""

problem = pddl"""
(define (problem storytellers-problem)
  (:domain storytellers)
  (:objects
    jacob wilhelm - storyteller
    hanau steinau - audience
    snowwhite rumpelstiltskin - story
  )
  (:init
    (= (story-set) (construct-set snowwhite rumpelstiltskin))
    (= (known jacob) (construct-set snowwhite))
    (= (known wilhelm) (construct-set rumpelstiltskin))
    (= (heard hanau) (empty-set))
    (= (heard steinau) (empty-set))
  )
  (:goal (and
      ; both audiences must hear all stories
      (= (heard hanau) (story-set))
      (= (heard steinau) (story-set))
  ))
)
"""

state = initstate(domain, problem)
```

As is the case for registering new predicates and functions, the `@register` macro is preferred whenever packages that depend on PDDL.jl need to be precompiled. However, it is also possible register and deregister theories at runtime with `register!` and `deregister!`:

```julia
Sets.register!()
Sets.deregister!()
```

## Predefined Theories

Alongside the `Sets` example shown above, a theory for handling `Arrays` is predefined as part of PDDL.jl:

```julia
PDDL.Sets
PDDL.Arrays
```

These theories are not registered by default, and should be registered with the `@register` macro before use.
