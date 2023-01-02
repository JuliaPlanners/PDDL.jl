# Generic concrete representations of PDDL domains, states, actions, etc. #

include("domain.jl")
include("problem.jl")
include("state.jl")
include("action.jl")
include("diff.jl")

domaintype(::Type{GenericState}) = GenericDomain
statetype(::Type{GenericDomain}) = GenericState
