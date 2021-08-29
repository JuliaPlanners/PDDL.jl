# Abstract interpreter semantics #

"Abstract (Cartesian) PDDL interpreter."
@kwdef struct AbstractInterpreter <: Interpreter
    abstractions::Dict{Symbol,Any} = Dict(:numeric => IntervalAbs)
    autowiden::Bool = true
end

include("utils.jl")
include("domain.jl")
include("satisfy.jl")
include("initstate.jl")
include("update.jl")

"""
    abstracted(domain; options...)

Construct an abstract domain from a concrete domain.
"""
abstracted(domain::GenericDomain; options...) =
    AbstractedDomain(domain; options...)

"""
    abstracted(domain, state; options...)
    abstracted(domain, problem; options...)

Construct an abstract domain and state from a concrete `domain` and `state`.
A `problem` can be provided instead of a `state`.
"""
function abstracted(domain::GenericDomain, state::GenericState; options...)
    absdom = abstracted(domain; options...)
    return (absdom, abstractstate(absdom, state))
end

abstracted(domain::GenericDomain, problem::GenericProblem) =
    abstracted(domain, initstate(domain, problem))

"""
    abstractstate(domain, state)

Construct a state in an abstract `domain` from a concrete `state.
"""
function abstractstate(domain::AbstractedDomain, state::GenericState)
    # Copy over facts
    abs_state = GenericState(copy(state.types), copy(state.facts))
    # Abstract non-Boolean values if necessary
    funcsigs = get_functions(domain)
    if isempty(funcsigs) return abs_state end
    absfuncs = domain.interpreter.abstractions
    for (term, val) in get_fluents(state)
        if is_pred(term, domain) continue end
        type = funcsigs[term.name].type
        val = get(absfuncs, type, identity)(val)
        abs_state[term] = val
    end
    return abs_state
end

abstractstate(domain::AbstractedDomain, problem::GenericProblem) =
    initstate(domain, problem)
