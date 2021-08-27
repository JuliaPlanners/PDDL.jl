# Concrete interpreter semantics
struct ConcreteInterpreter <: Interpreter end

include("satisfy.jl")
include("initstate.jl")
include("update.jl")
