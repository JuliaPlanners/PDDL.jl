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

"Return abstraction of a concrete domain."
abstraction(domain::ConcreteDomain; args...) =
    AbstractedDomain(domain; args...)
