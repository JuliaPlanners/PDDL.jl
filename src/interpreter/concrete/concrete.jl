# Concrete interpreter semantics #

"Concrete PDDL interpreter."
struct ConcreteInterpreter <: Interpreter end

include("domain.jl")
include("satisfy.jl")
include("initstate.jl")
include("update.jl")
