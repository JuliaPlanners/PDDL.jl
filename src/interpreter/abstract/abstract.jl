# Abstract interpreter semantics

"""
    AbstractInterpreter(
        type_abstractions = PDDL.default_abstypes(),
        fluent_abstractions = Dict(),
        autowiden = false
    )

Abstract PDDL interpreter based on Cartesian abstract interpretation of the
PDDL state. Fluents in the state are converted to abstract values based on
either their concrete type or fluent name, with fluent-specific abstractions
overriding type-based abstractions.

# Arguments

$(FIELDS)
"""
@kwdef struct AbstractInterpreter <: Interpreter
    "Mapping from PDDL types to the Julia type for abstract fluent values."
    type_abstractions::Dict{Symbol,Any} = default_abstypes()
    "Mapping from fluent names to the Julia type for abstract fluent values."
    fluent_abstractions::Dict{Symbol,Any} = Dict{Symbol,Any}()
    "Flag for automatic widening of values after a state transition."
    autowiden::Bool = false
end

include("domain.jl")
include("interface.jl")
include("satisfy.jl")
include("initstate.jl")
include("update.jl")
include("utils.jl")

"""
    abstracted(domain; options...)

Construct an abstract domain from a concrete domain.
See [`PDDL.AbstractInterpreter`](@ref) for the list of `options`.
"""
abstracted(domain::GenericDomain; options...) =
    AbstractedDomain(domain; options...)

"""
    abstracted(domain, state; options...)
    abstracted(domain, problem; options...)

Construct an abstract domain and state from a concrete `domain` and `state`.
A `problem` can be provided instead of a `state`.
See [`PDDL.AbstractInterpreter`](@ref) for the list of `options`.
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
    type_abstractions = domain.interpreter.type_abstractions
    fluent_abstractions = domain.interpreter.fluent_abstractions
    for (term, val) in get_fluents(state)
        if is_pred(term, domain) continue end
        abstype = get(fluent_abstractions, term.name) do
            get(type_abstractions, funcsigs[term.name].type, identity)
        end
        abs_state[term] = abstype(val)
    end
    return abs_state
end

abstractstate(domain::AbstractedDomain, problem::GenericProblem) =
    initstate(domain, problem)

"""
$(SIGNATURES)

Check if term is an abstracted fluent.
"""
function is_abstracted(term::Term, domain::AbstractedDomain)
    return is_abstracted(term.name, domain)
end

function is_abstracted(name::Symbol, domain::AbstractedDomain)
    haskey(domain.interpreter.fluent_abstractions, name) && return true
    sigs = get_functions(domain)
    return (haskey(sigs, name) &&
            haskey(domain.interpreter.type_abstractions, sigs[name].type))
end

    