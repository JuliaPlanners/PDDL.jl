# Function Interface

PDDL.jl defines a set of interface functions that serve as basic operations in a wide variety of symbolic planning algorithms and applications. These functions are intended to be low-level enough such that planning algorithms can be expressed primarily in terms of the operations they represent, but high-level enough so as to abstract away from implementational details.

## Evaluating Formulae and Expressions

The key distinguishing feature of symbolic planning is the ability to describe and determine whether certain facts about the world hold true (e.g. is the robot holding a block?), or evaluate numeric properties (e.g. the distance between two cities), with queries expressed in terms of first-order logic. As such, PDDL.jl provides the following functions which satisfy or evaluate first-order expressions in the context of a [`State`](@ref):

```@docs
satisfy
satisfiers
evaluate
```

## State Initialization and Transition

A PDDL [`Domain`](@ref) specifies the transition dynamics of a first order symbolic model of the world, while a PDDL [`Problem`](@ref) specifies the initial state and object set over which these dynamics are grounded. PDDL.jl thus provides functions for constructing an initial state for a domain and problem, and for simulating the transition dynamics:

```@docs
initstate
transition
transition!
```

## Forward Action Semantics

A widely-used strategy in symbolic planning is forward state space search, guided by a planning heuristic. These algorithms are built upon two basic operations to search forward in state space: querying the actions that are available in any given state, and executing an action to generate a successor state. These operations can be performed using the following functions:

```@docs
available
execute
execute!
```

## Inverse Semantics

Regression-based planners (e.g. [the classical STRIPS algorithm](https://en.wikipedia.org/wiki/Stanford_Research_Institute_Problem_Solver)) make use of the fact that is possible to plan by working *backwards* from a goal, repeatedly selecting actions that are relevant to achieving a goal state or specification. This motivates the following interface methods for (i) constructing *abstract* states from goal specifications and (ii) exposing the *inverse* semantics of actions:

```@docs
goalstate
relevant
regress
regress!
```
