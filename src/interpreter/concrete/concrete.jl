# Concrete interpreter semantics

"Concrete PDDL interpreter."
struct ConcreteInterpreter <: Interpreter end

include("interface.jl")
include("satisfy.jl")
include("initstate.jl")
include("goalstate.jl")
include("update.jl")
