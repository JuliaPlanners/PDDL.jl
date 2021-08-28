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

abstracted(domain::ConcreteDomain; args...) =
    AbstractedDomain(domain; args...)

function abstracted(domain::AbstractedDomain, state::GenericState)
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
