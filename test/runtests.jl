using PDDL, PDDL.Parser, Test

# Define equivalence shorthand for abstract interpreter testing
≃(a, b) = PDDL.equiv(a, b)

include("strips/test.jl")
include("typing/test.jl")
include("axioms/test.jl")
include("adl/test.jl")
include("numeric/test.jl")
include("functions/test.jl")
include("sets/test.jl")
