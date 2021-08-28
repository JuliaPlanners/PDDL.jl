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

abstraction(domain::ConcreteDomain; args...) =
    AbstractedDomain(domain; args...)

function abstraction(domain::AbstractedDomain, state::GenericState)
    absfuncs = domain.interpreter.abstractions
    abstracted = GenericState(state.types)
    fluentsigs = get_fluents(domain)
    for (term, val) in get_fluents(state)
        type = fluentsigs[term.name].type
        val = get(absfuncs, type, identity)(val)
        abstracted[term] = val
    end
    return abstracted
end
