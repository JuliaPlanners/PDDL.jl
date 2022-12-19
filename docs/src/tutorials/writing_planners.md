# Writing Planners

```@meta
Description = "How to write symbolic planners using PDDL.jl."
```

Using the [PDDL.jl interface](..\ref\interface.md), it is straightforward to implement planning algorithms which solve problems in PDDL domains. Since all domain and implementation specific details are encapsulated by the interface, the same algorithm can operate across multiple domains, and even multiple representations of the same domain (e.g. [interpreted](../ref/interpreter.md) vs. [compiled](../ref/compiler.md)).

In this tutorial, we present two simple planners as examples: forward breadth-first search, and backward breadth-first search.

## Forward Search

Our first example is **forward breadth-first search**, shown below. The algorithm accepts a [`Domain`](@ref) and [`Problem`](@ref), then constructs the initial state with the [`initstate`](@ref) function. It also extracts the goal formula using [`PDDL.get_goal`](@ref). The algorithm then searches the state space, iteratively expanding the successors of each state and available action in a [breadth-first order](https://en.wikipedia.org/wiki/Breadth-first_search):

```julia
function forward_bfs(domain::Domain, problem::Problem)
    # Initialize state and extract goal
    state = initstate(domain, problem)
    goal = PDDL.get_goal(problem)
    # Initialize search queue
    plan = []
    queue = [(state, plan)]
    while length(queue) > 0
        # Pop state and plan
        state, plan = popfirst!(queue)
        # Check if goal is satisfied
        if satisfy(domain, state, goal)
            # Return plan if goal is satisfied
            return plan
        end
        # Iterate over available actions and add successors to queue
        for action in available(domain, state)
            next_state = transition(domain, state, action)
            next_plan = [plan; action]
            push!(queue, (next_state, next_plan))
        end
    end
    # Return nothing upon failure
    return nothing
end
```

As can be seen, search proceeds by popping a state and corresponding plan off the search queue at each iteration, then checking if the state satisfies the goal using [`satisfy`](@ref). If the goal is satisfied, the plan is returned. If not, the state is expanded by iterating over each [`available`](@ref) action, and constructing the successor state for that action using the [`transition`](@ref) function. The successor state and its corresponding plan are added to queue. Search continues until either the queue is exhausted, or the goal is satisfied.

!!! note "Implementation Efficiency"
    While easy to understand, the implementation of breadth-first search presented here is memory inefficient because it stores the plan to each state as part of the search queue. Efficient implementations of planners using breadth-first search should be based off [Djikstra's algorithm](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm) instead.

## Regression Search

PDDL.jl also supports planning via **backward search**, also known as [**regression search**](https://artint.info/2e/html/ArtInt2e.Ch6.S3.html). Backward search operates by treating the goal condition as a *partial* or *abstract* state which only specifies that some predicates must be true. It then searches the space by considering all actions that could possibly achieve the current abstract state (called **relevant** actions), and inverting the semantics of each action (called **regression**). This results in a successor abstract state that represents the pre-image of the action: the set of all states that could have reached the current abstract state through that action.

A breadth-first version of backward search is shown below.

```julia
function backward_bfs(domain::Domain, problem::Problem)
    # Construct initial state and goal state
    init_state = initstate(domain, problem)
    state = goalstate(domain, problem)
    # Initialize search queue
    plan = []
    queue = [(state, plan)]
    while length(queue) > 0
        # Pop state and plan
        state, plan = popfirst!(queue)
        # Return plan if initial state implies the current abstract state
        if all(evaluate(domain, init_state, fluent) == val
               for (fluent, val) in PDDL.get_fluents(state))
            return plan
        end
        # Iterate over relevant actions and add pre-image to queue
        for action in relevant(domain, state)
            next_state = regress(domain, state, action)
            next_plan = [action; plan]
            push!(queue, (next_state, next_plan))
        end
    end
    # Return nothing upon failure
    return nothing
end
```

This algorithm is very similar to [`forward_bfs`](#forward-search): It first constructs an initial state (using [`initstate`](@ref)) and abstract goal state (using [`goalstate`](@ref)) from the domain and problem. It then searches in a breadth-first order from the abstract goal state, iterating over actions that are [`relevant`](@ref) to achieving the current abstract state, then computing the preimage induced by each action using [`regress`](@ref) and adding the resulting state to the queue. The search terminates when the initial state is found to be in the preimage of some action, i.e., all fluents that are true in the preimage are also true in the initial state.

!!! note "Support for Regression Search"
    PDDL.jl currently only provides correct implementations of regression search operations ([`relevant`](@ref) and [`regress`](@ref)) for STRIPS-style domains. This means that regression search is not currently supported for domains with non-Boolean fluents, negative preconditions, disjunctive preconditions, quantified preconditions, or conditional effects.

## Existing Planners

While PDDL.jl makes it relatively easy to implement planning algorithms from scratch, the performance and (re)usability of these algorithms require more careful design. As such, the PDDL.jl ecosystem also includes the [**SymbolicPlanners.jl**](https://github.com/JuliaPlanners/SymbolicPlanners.jl) library, which provides a wide array of planning algorithms and heuristics that have [comparable performance](https://github.com/JuliaPlanners/SymbolicPlanners.jl#performance) to other commonly-used planning systems. Below, we show how to use SymbolicPlanners.jl to solve a Blocksworld problem via [A* search](https://en.wikipedia.org/wiki/A*_search_algorithm) with the [additive heuristic](https://doi.org/10.1016/S0004-3702%2801%2900108-4):

```julia
using PDDL, PlanningDomains, SymbolicPlanners

# Load Blocksworld domain and problem
domain = load_domain(:blocksworld)
problem = load_problem(:blocksworld, "problem-4")
state = initstate(domain, problem)
goal = PDDL.get_goal(problem)

# Construct A* planner with h_add heuristic
planner = AStarPlanner(HAdd())

# Solve the problem using the planner
sol = planner(domain, state, goal)
```

We can check that the resulting solution achieves the goal as desired:

```julia-repl
julia> goal
and(on(d, c), on(c, b), on(b, a), on(a, e))

julia> collect(sol)
10-element Vector{Any}:
 unstack(b, a)
 put-down(b)
 unstack(a, d)
 stack(a, e)
 pick-up(b)
 stack(b, a)
 pick-up(c)
 stack(c, b)
 pick-up(d)
 stack(d, c)

julia> satisfy(domain, sol.trajectory[end], goal)
true
```

For more information about the planners and heuristics provided by SymbolicPlanners.jl, consult the [README](https://github.com/JuliaPlanners/SymbolicPlanners.jl).
