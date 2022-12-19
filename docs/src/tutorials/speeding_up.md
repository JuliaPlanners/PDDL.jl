# Speeding Up PDDL.jl

```@meta
Description = "How to compile PDDL domains to speed up PDDL.jl."
```

By default, PDDL.jl uses the [built-in PDDL interpreter](../ref/interpreter.md) to execute actions, determine the set of available actions, and perform other basic planning operations. However, because the interpreter is not optimized for speed, planning algorithms that use the interpreter are considerably slower than state-of-the-art planners.

```@raw html
<figure style="text-align:center">
    <img src="../../assets/performance-comparison.svg" alt="Blocksworld solution runtimes vs. problem size for PDDL.jl, Pyperplan, and FastDownward, each using A* search with the additive heuristic." width="80%"/>
    <figcaption>Blocksworld solution times for PDDL.jl vs. baselines, each using A* search with the additive heuristic.</figcaption>
</figure>
```

Fortunately, PDDL.jl also provides [a PDDL compiler](../ref/compiler.md) that is optimized for speed and low memory consumption. As can be seen in the (log-scale) graph above, using the compiler to solve Blocksworld problems is 10 times faster than the interpreter, within an order of magnitude of the state-of-the-art [FastDownward](https://www.fast-downward.org/) planner, and 20 times faster than [Pyperplan](https://github.com/aibasel/pyperplan), a Python-based planning system. In this tutorial, we show how to use the PDDL compiler to speed up planning algorithms, and explain how these speed-ups are achieved.

## Using the Compiler

To use the PDDL compiler, just call the [`compiled`](@ref) function on a PDDL domain and problem. This returns a compiled domain and initial state:

```julia
using PDDL, PlanningDomains

# Load a generic representation of PDDL domain and problem
domain = load_domain(:blocksworld)
problem = load_problem(:blocksworld, "problem-10")

# Compile the domain and problem to get a compiled domain and state
c_domain, c_state = compiled(domain, problem)
```

Alternatively, [`compiled`](@ref) can be called on a non-compiled domain and (initial) state:

```julia
# Construct initial state from domain and problem
state = initstate(domain, problem)

# Compile the domain and state to get a compiled domain and state
c_domain, c_state = compiled(domain, state)
```

The compiled outputs `c_domain` and `c_state` can then be used with the [PDDL.jl interface](../ref/interpreter.md), or with [an existing planner from SymbolicPlanners.jl](writing_planners.md#Existing-Planners):

```julia
using SymbolicPlanners

# Call A* search on compiled domain and initial state
goal = PDDL.get_goal(problem)
planner = AStarPlanner(HAdd())
sol = planner(c_domain, c_state, goal)

# Execute resulting plan on the compiled initial state
plan = collect(sol)
for act in plan
    c_state = transition(c_domain, c_state, act)
end

# Check that the goal is achieved in the final state
@assert satisfy(c_domain, c_state, goal)
```

Factoring out the initial cost of [Julia's just-ahead-of-time compilation](https://discourse.julialang.org/t/so-does-julia-compile-or-interpret/56073/2?u=xuan), planning over the compiled domain and state should lead to runtimes that are 10 times faster or more, compared to the PDDL.jl interpreter.

## State Compilation

One way in which the PDDL.jl compiler reduces runtime is by generating *compiled state representations* that compactly represent the set of facts and fluent values in a state.  These representations take advantage of the fixed number of objects in standard PDDL problems, allowing for the generation of finite-object state representations with a known size in advance.

To illustrate the benefits of state compilation, consider the initial state of a Blocksworld problem with 3 blocks, as shown in the [Getting Started](getting_started.md/Loading-Problems) tutorial. The generic state representation used by the PDDL.jl interpreter stores all Boolean fluents in a `Set` data structure, and non-Boolean fluents in a `Dict`. This consumes a fair amount of memory, and suffers from hashing overhead when looking up the value of a fluent:

```
GenericState
    types -> Set{Compound} with 3 elements
       pddl"(block a)",
       pddl"(block b)",
       pddl"(block c)"
    facts -> Set{Term} with 7 elements
       pddl"(handempty)",
       pddl"(clear a)",
       pddl"(clear b)",
       pddl"(clear c)"
       pddl"(ontable a)",
       pddl"(ontable b)",
       pddl"(ontable c)"
    values -> Dict{Term,Any} with 0 entries

Size: 1720 bytes
Median Access Time: 394 ns
```

In constrast, the compiled state representation is shown below. Predicate values are stored in memory-efficient bit-arrays, with dimensionality corresponding to the arity of each predicate (1 dimension for `(holding ?x)`, 2 dimensions for `(on ?x ?y)`). Furthermore, each bit array is a field with a fixed name in the compiled data structure. Together, this leads to much lower memory consumption and access times:

```
CompiledBlocksworldState
    handempty ->
        true
    clear -> 3-element BitVector
        1  1  1
    holding -> 3-element BitVector
        0  0  0
    ontable -> 3-element BitVector
        1  1  1
    on -> 3x3 BitMatrix
        0  0  0
        0  0  0
        0  0  0

Size: 336 bytes
Median Access Time: 58.5 ns
```

Generating a compiled state representation requires knowing the number of objects in the problem, their types, and their names. This is why the [`compiled`](@ref) function requires either the problem or initial state as an input.

## Action Compilation

PDDL.jl also supports *compiled action semantics*, generating specialized implementations of the [`execute`](@ref) and [`available`](@ref) interface functions for each action schema in the domain. This makes use of Julia's support for multiple dispatch: By generating concrete subtypes of the [`Action`](@ref) datatype for each action schema, specialized methods can be defined for each subtype.

As an example, consider the compiled implementation of [`execute`](@ref) for the `(stack ?x ?y)` action in the Blocksworld domain. Instead of interpreting the effect formula associated with the action each time it is executed, the compiled version of [`execute`](@ref) directly modifies the appropriate entries of the compiled state representation for the Blocksworld domain (shown below with comments):

```julia
function execute(domain, state, action::CompiledStackAction, args)
    state = copy(state)
    # Get object indices for arguments
    x_idx = objectindex(state, :block, args[1].name)
    y_idx = objectindex(state, :block, args[2].name)
    # Assign new values to affected fluents
    state.handempty = true
    state.clear[x_idx] = true
    state.clear[y_idx] = false
    state.holding[x_idx] = false
    state.on[x_idx, y_idx] = true
    return state
end
```

All of the above code is compiled from PDDL to Julia, which in turn gets compiled to high performance machine code by Julia's own compiler. By directly modifying the state representation, the compiled implementation can achieve median runtimes up to 60 times faster than the interpreted version of  [`execute`](@ref).

## Compiler Limitations

While domain compilation leads to significant performant benefits, the compiler also has several limitations in the current version of PDDL.jl:

  - **Top-level only**: Because [`compiled`](@ref) defines new types and methods, it should only be called at the top-level in order to avoid world-age errors.

  - **Precompilation not supported**: Since [`compiled`](@ref) evaluates code in the `PDDL` module, it will lead to precompilation errors when used in another module or package. Modules which call [`compiled`](@ref) should hence disable precompilation, or include make calls to [`compiled`](@ref) only in the [`__init__()` function](https://docs.julialang.org/en/v1/manual/modules/#Module-initialization-and-precompilation).

  - **Regression not supported**: The compiler does not currently implement the interface functions for reverse action semantics, meaning that it cannot be used for regression search.

  - **Compilation overhead**: The cost of compiling generated Julia code on its first run can be significant relative to total runtime for small problems. This means that compilation may not be ideal for one-off use for states with small numbers of objects.

  - **No generalization across problems in the same domain**: The compiled code and state representations generated by the compiler currently assume a fixed set of objects. To use the compiler with problems in the same domain, but defined over a different set of of objects the [`compiled`](@ref) function has to be invoked again.

Due to these limitations, it may sometimes be preferable to use the PDDL.jl interpreter instead of the compiler, especially when generality is more important than speed. However, most of these limitations are planned to be removed in future versions of PDDL.jl.
