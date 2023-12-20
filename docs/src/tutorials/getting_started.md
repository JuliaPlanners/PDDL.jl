# Getting Started

```@meta
Description = "A tutorial on getting started with PDDL.jl."
```

Welcome to using PDDL.jl! This tutorial covers how to install PDDL.jl, how to load your first domain and problem, how to manipulate and inspect states and actions, and how to write and execute a plan that achieves a goal.

## Installation

First, download and run Julia, [available here](https://julialang.org/downloads/) (version 1.3 or later required). Optionally, [create your own project](https://pkgdocs.julialang.org/v1/environments/) and activate its environment. Next, press `]` in the Julia REPL to enter the package manager, then install the registered version of PDDL.jl by running:
```
add PDDL
```

To install the latest development version, you may instead run:
```
add https://github.com/JuliaPlanners/PDDL.jl.git
```

PDDL.jl can now be used in the Julia REPL, or at the top of a script:
```julia
using PDDL
```

## Loading Domains and Problems

PDDL stands for the [Planning Domain Definition Language](https://en.wikipedia.org/wiki/Planning_Domain_Definition_Language), a formal language for specifying the semantics of planning domains and problems. PDDL domain and problem definitions are typically saved as text files with the `.pddl` extension.

### Loading Domains

A **PDDL domain** defines the high-level "physics" or transition dynamics of a planning task. A classic example is [Blocksworld](https://en.wikipedia.org/wiki/Blocks_world), a domain where blocks may be stacked on top of each other, or placed on a table:

```lisp
(define (domain blocksworld)
  (:requirements :strips :typing :equality)
  (:types block)
  (:predicates (on ?x ?y - block) (ontable ?x - block) (clear ?x - block)
               (handempty) (holding ?x - block))
  (:action pick-up
   :parameters (?x - block)
   :precondition (and (clear ?x) (ontable ?x) (handempty))
   :effect (and (not (ontable ?x)) (not (clear ?x))
                (not (handempty))  (holding ?x)))
  (:action put-down
   :parameters (?x - block)
   :precondition (holding ?x)
   :effect (and (not (holding ?x)) (clear ?x)
                (handempty) (ontable ?x)))
  (:action stack
   :parameters (?x ?y - block)
   :precondition (and (holding ?x) (clear ?y) (not (= ?x ?y)))
   :effect (and (not (holding ?x)) (not (clear ?y)) (clear ?x)
                (handempty) (on ?x ?y)))
  (:action unstack
   :parameters (?x ?y - block)
   :precondition (and (on ?x ?y) (clear ?x) (handempty) (not (= ?x ?y)))
   :effect (and (holding ?x) (clear ?y) (not (clear ?x))
                (not (handempty)) (not (on ?x ?y))))
)
```

Suppose this domain definition is saved in a file named `blocksworld.pddl` in the current directory. After loading PDDL.jl with `using PDDL`, we can load the Blocksworld domain by calling [`load_domain`](@ref):

```julia
domain = load_domain("blocksworld.pddl")
```

We can then inspect the name of domain, and the list of action names:

```julia-repl
julia> PDDL.get_name(domain)
:blocksworld

julia> PDDL.get_actions(domain) |> keys .|> string
4-element Vector{String}:
 "pick-up"
 "unstack"
 "put-down"
 "stack"
```

### Loading Problems

PDDL domains only define the general semantics of the planning task that apply across any set of objects or goals. To fully define a planning task, we also need to load a **PDDL problem**, which defines an initial state, and a goal to be achieved:

```lisp
(define (problem blocksworld-problem)
  (:domain blocksworld)
  (:objects a b c - block)
  (:init (handempty) (ontable a) (ontable b) (ontable c)
         (clear a) (clear b) (clear c))
  (:goal (and (clear c) (ontable b) (on c a) (on a b)))
)
```

In this problem, there are 3 blocks, `a`, `b`, and `c`, which are all initially placed on the table (`ontable`), with no other blocks placed on them (`clear`). The goal is to stack the blocks such that `c` is on `a` is on `b`.

Suppose the problem definition is saved in `blocksworld-problem.pddl`. We can load it by calling [`load_problem`](@ref):

```julia
problem = load_problem("blocksworld-problem.pddl")
```

We can then inspect the list of objects, and the goal to be reached:

```julia-repl
julia> PDDL.get_objects(problem) |> println
Const[a, b, c]

julia> PDDL.get_goal(problem) |> write_pddl
"(and (clear c) (ontable b) (on c a) (on a b))"
```

### Loading From A Repository

A wide variety of standard PDDL domains and problems can be found online, such as [this repository](https://github.com/potassco/pddl-instances) of instances from the International Planning Competition (IPC). To ease the (down)loading of these domains and problems, the PDDL.jl ecosystem includes [PlanningDomains.jl](https://github.com/JuliaPlanners/PlanningDomains.jl), which contains both a built-in repository of domains and problems, and an interface for accessing domains and problems from other online repositories.

PlanningDomains.jl can be installed from the Pkg REPL as per usual:
```
add PlanningDomains
```

Once installed, we can use PlanningDomains.jl to directly load Blocksworld domains and problems:

```julia
using PlanningDomains

domain = load_domain(:blocksworld)
problem = load_problem(:blocksworld, "problem-2")
```

We can also specify external repositories to download from, such as the previously mentioned repository of [IPC domains and problems](https://github.com/potassco/pddl-instances):

```julia
domain = load_domain(IPCInstancesRepo, "ipc-2000", "blocks-strips-typed")
problem = load_problem(IPCInstancesRepo, "ipc-2000", "blocks-strips-typed", "problem-2")
```

## Constructing and Inspecting States

Now that we've loaded a domain and problem, we can construct the initial state (specified by the problem file) using the [`initstate`](@ref) function:

```julia
state = initstate(domain, problem)
```

### Inspecting Facts and Relations

Conceptually, a **state** consists of a set of objects, and a set of true facts and relations about those objects. We can list the set of facts using [`PDDL.get_facts`](@ref):

```julia-repl
julia> PDDL.get_facts(state)
Set{Term} with 7 elements:
  clear(a)
  ontable(b)
  clear(b)
  handempty
  ontable(a)
  ontable(c)
  clear(c)
```

!!! note "PDDL vs. Prolog-style syntax"
    Facts are printed in Prolog-style syntax by default: `ontable(a)` in Prolog is the same as `(ontable a)` in PDDL. This is because PDDL.jl uses [Julog.jl](https://github.com/ztangent/Julog.jl) to represent terms and expressions in first-order logic.

In addition to listing facts, we can query the truth value of specific terms using the [`satisfy`](@ref) function:

```julia-repl
julia> satisfy(domain, state, pddl"(ontable a)")
true

julia> satisfy(domain, state, pddl"(on a b)")
false
```

Here, we used the `pddl"..."` string macro to construct a first-order [`Term`](@ref). This allows us to write `pddl"(on a b)"` as syntactic sugar for the expression `Compound(:on, Term[Const(:a), Const(:b)])`. (It is also [possible to *interpolate* values](../ref/parser_writer.md#Interpolation) when using the `pddl"..."` macro.)

Besides querying whether particular terms are true or false, we can also ask PDDL.jl to return all satisfying assignments to a logical formula with free variables using the [`satisfiers`](@ref) function:

```julia-repl
julia> satisfiers(domain, state, pddl"(and (ontable ?x) (clear ?x))")
3-element Vector{Any}:
 {X => b}
 {X => a}
 {X => c}
```

Our query `pddl"(and (ontable ?x) (clear ?x))"` expresses that some object `?x` is on the table, and is clear (i.e. has no other blocks on top of it), where `?x` is PDDL syntax for a variable in a [first-order formula](https://en.wikipedia.org/wiki/First-order_logic#Formulas). Since blocks `a`, `b` and `c` all satisfy the query, [`satisfiers`](@ref) returns a list of corresponding variable substitutions. Note that the PDDL variable `?x` gets rendered in Prolog-style syntax as a capital `X`, by the convention in Prolog that capital letters refer to variables.

### Inspecting Non-Boolean Fluents

PDDL is not limited to domains where object properties and relations must have Boolean values. For example, the [Zeno Travel domain](https://github.com/potassco/pddl-instances/blob/master/ipc-2002/domains/zenotravel-numeric-automatic/domain.pddl) includes numeric properties and relations, such as the distance between two cities, or the amount of fuel in a plane. We can construct and inspect a state in this domain as well:

```julia
zt_domain = load_domain(:zeno_travel)
zt_problem = load_problem(:zeno_travel, "problem-1")
zt_state = initstate(zt_domain, zt_problem)
```

To inspect all properties and relations (Boolean or otherwise) in this state, we can iterate over the list of pairs returned by [`PDDL.get_fluents`](@ref):

```julia-repl
julia> PDDL.get_fluents(zt_state) |> collect
13-element Vector{Pair}:
  at(plane1, city0) => true
 at(person1, city0) => true
    onboard(plane1) => 0
  slow-burn(plane1) => 4
                    ⋮
       fuel(plane1) => 3956
  fast-burn(plane1) => 15
 zoom-limit(plane1) => 8
   capacity(plane1) => 10232
```

These properties and relations are called [**fluents**](https://en.wikipedia.org/wiki/Fluent_(artificial_intelligence)), a term historically used in AI research to describe facts about the world that may change over time.

Fluents are sometimes also called "state variables", but we avoid that terminology to prevent confusion with variables in the context of first-order terms and formulae. In keeping with the terminology of [first-order logic](https://en.wikipedia.org/wiki/First-order_logic), Boolean fluents such as `(at ?plane ?city)` are also called **predicates**, and non-Boolean fluents such as `(fuel ?plane)` are called **functions** (because they map objects to values).

!!! note "Omitted Predicates"
    For conciseness, some implementations of the PDDL.jl interface will omit predicates that are false from the list returned by [`PDDL.get_fluents`](@ref), as is the case above.

In addition to listing fluents, we can evaluate specific fluents using the [`evaluate`](@ref) function. Below, we query the amount of fuel in `plane1`:

```julia-repl
julia> evaluate(zt_domain, zt_state, pddl"(fuel plane1)")
3956
```

We can also evaluate compound expressions of multiple fluents. For example, we might be curious to know the amount of additional fuel that `plane1` can hold. As syntactic sugar for `evaluate(domain, state, term)`, we can also use the syntax `domain[state => term]`:

```julia-repl
julia> evaluate(zt_domain, zt_state, pddl"(- (capacity plane1) (fuel plane1))")
6276

julia> zt_domain[zt_state => pddl"(- (capacity plane1) (fuel plane1))"]
6276
```

For *non-compound* expressions stored directly in the state, we can use [`PDDL.get_fluent`](@ref) to look up the value of a `term` in `state`, or `state[term]` for short:

```julia-repl
julia> state[pddl"(on a b)"] # Blocksworld query
false

julia> zt_state[pddl"(fuel plane1)"] # Zeno Travel query
3956
```

### Inspecting Objects and Object Types

Since PDDL states consist of sets of (optionally typed) objects, PDDL.jl provides the [`PDDL.get_objects`](@ref) function to list all objects in a state, as well as all objects of particular type:

```julia-repl
julia> PDDL.get_objects(state) |> println # Blocksworld objects
Const[c, a, b]

julia> PDDL.get_objects(zt_state, :aircraft) |> println # Zeno Travel aircraft
Const[plane1]

julia> PDDL.get_objects(zt_domain, zt_state, :movable) |> println # Zeno Travel movables
Const[person1, plane1]
```

Note that in the third call to [`PDDL.get_objects`](@ref), we also provided the domain as the first argument. This is because the domain stores information about the type hierarchy, and the `movable` type in the Zeno Travel domain is abstract: There are no objects in the state which have the type `movable`. There only objects of its subtypes, `person` and `aircraft`. We can inspect the type hierarchy of a domain using [`PDDL.get_typetree`](@ref):

```julia-repl
julia> PDDL.get_typetree(zt_domain)
Dict{Symbol, Vector{Symbol}} with 5 entries:
  :object   => [:movable, :city]
  :movable  => [:aircraft, :person]
  :aircraft => []
  :person   => []
  :city     => []
```

Finally, we can inspect the type of a specific object using [`PDDL.get_objtype`](@ref):

```julia-repl
julia> PDDL.get_objtype(zt_state, pddl"(person1)")
:person
```

## Executing Actions and Plans

PDDL domains not only define the predicates and functions which describe a state, but also a set of actions which can modify a state. Having learned how to inspect the contents of a state, we can now modify them using actions.

### Instantiating Actions

In PDDL and symbolic planning more broadly, we distinguish between **action schemas** (also known as **operators**), which specify the general semantics of an action, and **ground actions**, which represent instantiations of actions for specific objects. We can inspect the definition of an action schema in a domain using [`PDDL.get_action`](@ref), such as the definition of `stack` below:

```julia-repl
julia> PDDL.get_action(domain, :stack) |> write_pddl |> print
(:action stack
 :parameters (?x ?y - block)
 :precondition (and (holding ?x) (clear ?y) (not (= ?x ?y)))
 :effect (and (not (holding ?x)) (not (clear ?y)) (clear ?x) (handempty) (on ?x ?y)))
```

The `stack` schema has two **parameters** (or arguments) of type `block`. This means that ground instances of the `stack` schema have to be applied to two `block` objects. The schema also specifies a **precondition** formula, which has to hold true in order for the action to be executable (a.k.a. available) in the current state. Finally, the schema contains an **effect** formula, which specifies facts that will either be added or deleted in the next state. In domains with non-Boolean fluents, effects may also assign or modify the values of fluents.

To refer to a specific application of this action schema to blocks `a` and `b` (i.e., a ground action), we can simply write `pddl"(stack a b)"`, which constructs a `Term` with `stack` as its name, and with `a` and `b` as arguments:

```julia-repl
julia> pddl"(stack a b)" |> dump
Compound
  name: Symbol stack
  args: Array{Term}((2,))
    1: Const
      name: Symbol a
    2: Const
      name: Symbol b
```

If unspecified, whether we are referring to action schemas or ground actions shall be clear from context.

### Listing Available Actions

For our initial state in the Blocksworld domain, we can iterate over the list of available ground actions (i.e. those with satisfied preconditions) using the [`available`](@ref) function:

```julia-repl
julia> available(domain, state) |> collect
3-element Vector{Compound}:
 pick-up(a)
 pick-up(b)
 pick-up(c)
```

Note that [`available`](@ref) returns an iterator over such actions, so we have to `collect` this iterator in order to get a `Vector` result. As before, action `Term`s are printed in Prolog-style syntax.

### Executing Actions

Since we now know which actions are available, we can [`execute`](@ref) one of them to get another state:

```julia-repl
julia> next_state = execute(domain, state, pddl"(pick-up a)");

julia> satisfy(domain, next_state, pddl"(holding a)")
true
```

We see that after executing the `pddl"(pick-up a)"` action, block `a` is now being held. In contrast, if we try to execute a non-available action, PDDL.jl will throw an error:

```julia-repl
julia> next_state = execute(domain, state, pddl"(stack a b)");
ERROR: Precondition (and (holding ?x) (clear ?y) (not (= ?x ?y))) does not hold.
⋮
```

Instead of using [`execute`](@ref), we can also use the [`transition`](@ref) function. For domains written in standard PDDL, these functions have the same behavior, but there are extensions of PDDL which include events and processes that are handled by [`transition`](@ref) only. Note that both [`execute`](@ref) and [`transition`](@ref) do not mutate the original state passed in as an argument. For mutating versions, see [`execute!`](@ref) and [`transition!`](@ref).

### Executing and Simulating Plans

Now that we know how to execute an action, we can execute a series of actions (i.e. a plan) to achieve our goal in the Blocksworld domain. We can do this by repeatedly calling  [`transition`](@ref):

```julia
state = initstate(domain, problem)
state = transition(domain, state, pddl"(pick-up a)")
state = transition(domain, state, pddl"(stack a b)")
state = transition(domain, state, pddl"(pick-up c)");
state = transition(domain, state, pddl"(stack c a)");
```

And then check that our goal is indeed satisfied:

```julia-repl
julia> goal = PDDL.get_goal(problem) # Our goal is stack `c` on `a` on `b`
and(clear(c), ontable(b), on(c, a), on(a, b))

julia> satisfy(domain, state, goal)
true
```

Rather than repeatedly call [`transition`](@ref), we can use the [`PDDL.simulate`](@ref) function to directly simulate the end result of a sequence of actions:

```julia
state = initstate(domain, problem)
plan = @pddl("(pick-up a)", "(stack a b)", "(pick-up c)", "(stack c a)")
end_state = PDDL.simulate(EndStateSimulator(), domain, state, plan)
```

As before, the goal is satisfied in the final state:

```julia-repl
julia> satisfy(domain, end_state, goal)
true
```

The first argument to [`PDDL.simulate`](@ref) is a concrete instance of a [`Simulator`](@ref), which controls what information is collected as the simulation progresses. By default, the first argument is a [`StateRecorder`](@ref), which leads [`PDDL.simulate`](@ref) to return the trajectory of all states encountered, including the first:

```julia-repl
julia> traj = PDDL.simulate(domain, state, plan);

julia> eltype(traj)
GenericState

julia> length(traj)
5
```

You've now learned how to load PDDL domains and problems, construct and inspect states, and execute (sequences of) actions -- congratulations! In the [next tutorial](writing_planners.md), you can learn how to write your very own planning algorithms using the functions introduced here.
