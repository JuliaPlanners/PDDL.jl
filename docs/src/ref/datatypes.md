# Concepts and Data Types

Symbolic planning is a general term for approaches to automated planning that describe the environment and its dynamics in terms of high-level symbols. PDDL is one way of representing such symbolic knowledge, but there are many related formalisms which the shared concepts of fluents, states, actions, domains, and problems. Here we provide general definitions of these concepts, and also describe the system of data types in PDDL.jl that mirror these concepts. A graphical overview is shown below.

```@raw html
<div style="text-align:center">
    <img src="../../assets/concepts-datatypes.svg" alt="A graphical overview of concepts in symbolic planning and their corresponding datatypes." width="80%"/>
</div>
```

## Fluents and Terms

Fluents define (relational) state variables which may (or may not) change over time. A **fluent** of arity $$n$$ is a predicate (Boolean-valued) or function (non-Boolean) with $$n$$ object arguments, which describes some property or relation over those objects. A **ground fluent** is a fluent defined over particular set of objects (i.e. none of its arguments are free variables). Arguments may optionally be type-restricted.

!!! note "Example"
    The fluent `(on ?x ?y)` is named `on`, has arity 2, and describes whether some object denoted by the variable `?x` is stacked on top of `?y`. The ground fluent `(on a b)` denotes that object `a` is stacked on top of object `b` when true.

The `Term` data type is used to represent fluents, but also object constants, variables, logical formulae, effect formulae, and ground actions. Every `Term` has a `name` property, as well as an `args` property, representing the (potentially empty) list of sub-terms it has as arguments. `Term`s are inherited from the [Julog.jl](https://github.com/ztangent/Julog.jl) package for Prolog-style reasoning about first-order logic.

```@docs
Term
```

There are three subtypes of `Term`s:
  - `Const` terms, which are used to represent object constants, and have no arguments.
  - `Var` terms are used to represent variables in the context of first-order expressions.
  - `Compound` terms are terms with arguments. They can be used to represent fluents, action preconditions or effects, logical expressions, or [ground actions](../tutorials/getting_started.md#Instantiating-Actions).

To construct a `Term` using PDDL syntax, the [`@pddl`](@ref) macro or `pddl"..."` [string macro](https://docs.julialang.org/en/v1/manual/metaprogramming/#meta-non-standard-string-literals) can be used:

```julia-repl
julia> pddl"(on a b)" |> dump
Compound
  name: Symbol on
  args: Array{Term}((2,))
    1: Const
      name: Symbol a
    2: Const
      name: Symbol b
```

### Fluent Signatures

In the context of a planning [`Domain`](@ref), (lifted) fluents often have specific type signatures. For example, fluent arguments may be restricted to objects of particular types, and their values may be `:boolean` or `:numeric`. This type information is stored in the [`PDDL.Signature`](@ref) data type:

```@docs
PDDL.Signature
PDDL.arity
```

## States

In symbolic planning, states are symbolic descriptions of the environment and its objects at a particular point in time. Formally, given a finite set of fluents $$\mathcal{F}$$, a **state** $$s$$ is composed of a set of (optionally typed) objects $$\mathcal{O}$$, and valuations of ground fluents $$\mathcal{F}(\mathcal{O})$$ defined over all objects in $$\mathcal{O}$$ of the appropriate types. Each ground fluent thus refers to a state variable. For a ground fluent $$f \in \mathcal{F}(\mathcal{O})$$, we will use the notation $$s[f] = v$$ to denote that $$f$$ has value $$v$$ in state $$s$$.

!!! note "Example"
    Given the fluents `(on ?x ?y)` and `(on-table ?x)` that describe a state $s$ with objects `a` and `b`, there are six ground fluents whose values are defined in the state:  `(on a a)`, `(on a b)`, `(on b a)`, `(on b b)`, `(on-table a)` and `(on-table b)`. The expression $$s[$$`(on a b)`$$] =$$ `true` means that object `a` is on top of `b` in state $$s$$.

In PDDL.jl, states are represented by the [`State`](@ref) abstract type:

```@docs
State
```

The following accessor methods are defined for a `State`:

```@docs
PDDL.get_objects(::State)
PDDL.get_objtypes(::State)
PDDL.get_objtype(::State, ::Any)
PDDL.get_facts(::State)
PDDL.get_fluent(::State, ::Term)
PDDL.set_fluent!(::State, ::Any, ::Term)
PDDL.get_fluents(::State)
```

## Actions

As described in the [Getting Started](../tutorials/getting_started.md#Instantiating-Actions), symbolic planning formalisms distinguish between **action schemas** (also known as **operators**), which specify the general semantics of an action, and **ground actions**,  which represent instantiations of an action schema for specific objects.

An action schema comprises:
- A *name* that identifies the action.
- A list of (optionally typed) *parameters* or *arguments* that an action operates over.
- A *precondition* formula, defined over the parameters, that has to hold true for the action to be executable.
- An *effect* formula, defined over the parameters, specifying how the action modifies the state once it is executed.

!!! note "Example"
    An example action schema definition in PDDL is shown below:
    ```lisp
    (:action stack
     :parameters (?x ?y - block)
     :precondition (and (holding ?x) (clear ?y) (not (= ?x ?y)))
     :effect (and (not (holding ?x)) (not (clear ?y)) (clear ?x) (handempty) (on ?x ?y)))
    ```
    This schema defines the semantics of an action named `stack` and has two parameters of type `block`. Its precondition states that block `?x` has to be held, block `?y` has to be clear (no other block is on top of it), and that`?x` is not the same as `?y`. Its effect states that in the next state, `?x` will no longer be held, and that it will be instead be placed on top of block `?y`.

In PDDL.jl, action schemas are represented by the [`Action`](@ref) abstract type:

```@docs
Action
```

The following accessor methods are defined for an `Action`:

```@docs
PDDL.get_argvars(::Action)
PDDL.get_argtypes(::Action)
PDDL.get_precond(::Action)
PDDL.get_effect(::Action)
```

In contrast to action schemas, ground actions are represented with the [`Term`](@ref) data type. This is because the `name` property of a [`Term`](@ref) is sufficient to identify an action schema in the context of a planning domain, and the `args` property can be used to represent action parameters.

There also exists a special no-op action schema, denoted [`PDDL.NoOp()`](@ref) in Julia code. The corresponding ground action can be expressed as [`PDDL.no_op`](@ref) or `pddl"(--)"`.

```@docs
PDDL.NoOp
PDDL.no_op
```

### State Differences

For some use cases, such as [action grounding](utilities.md#Grounding) or [interpreted execution](interpreter.md), it can be helpful to more explicitly represent the effects of an action as a difference between [`State`](@ref)s. PDDL.jl uses the [`PDDL.Diff`](@ref) abstract data type to represent such differences, including [`PDDL.GenericDiff`](@ref)s and [`PDDL.ConditionalDiff`](@ref)s.

```@docs
PDDL.Diff
PDDL.GenericDiff
PDDL.ConditionalDiff
```

Multiple [`PDDL.Diff`](@ref)s can be combined using the [`PDDL.combine!`](@ref) and [`PDDL.combine`](@ref) functions:

```@docs
PDDL.combine!
PDDL.combine
```

## Domains

A **planning domain** is a (first-order) symbolic model of the environment, specifying the predicates and functions that can be used to describe the environment, and the actions that can be taken in the environment, including their preconditions and effects. Some domains may also specify the types of objects that exist, or include domain axioms that specify which predicates can be derived from others.

In PDDL.jl, domains are represented by the [`Domain`](@ref) abstract type:

```@docs
Domain
```

The following accessor methods are defined for a `Domain`:

```@docs
PDDL.get_name(::Domain)
PDDL.get_typetree(::Domain)
PDDL.get_types(::Domain)
PDDL.get_subtypes(::Domain, ::Symbol)
PDDL.get_predicates(::Domain)
PDDL.get_predicate(::Domain, ::Symbol)
PDDL.get_functions(::Domain)
PDDL.get_function(::Domain, ::Symbol)
PDDL.get_fluents(::Domain)
PDDL.get_fluent(::Domain, ::Symbol)
PDDL.get_axioms(::Domain)
PDDL.get_axiom(::Domain, ::Symbol)
PDDL.get_actions(::Domain)
PDDL.get_action(::Domain, ::Symbol)
```

## Problems

A **planning problem** for a particular domain specifies both the
initial state of the environment, and the task specification to be achieved. Typically, the task specification is a goal to be achieved, specified as a logical formula to be satisfied. However, planning problems can also include other specifications, such as a cost metric to minimize, and temporal constraints on the plan or state trajectory.

In PDDL.jl, problems are represented by the [`Problem`](@ref) abstract type:

```@docs
Problem
```

The following accessor methods are defined for a `Problem`:

```@docs
PDDL.get_name(::Problem)
PDDL.get_domain_name(::Problem)
PDDL.get_objects(::Problem)
PDDL.get_objtypes(::Problem)
PDDL.get_init_terms(::Problem)
PDDL.get_goal(::Problem)
PDDL.get_metric(::Problem)
PDDL.get_constraints(::Problem)
```
