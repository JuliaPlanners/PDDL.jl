using PDDL, PDDL.Parser, Test

# Define equivalence shorthand for abstract interpreter testing
function ≃(a, b)
    val = PDDL.equiv(a, b)
    return (val == true) || (val == PDDL.both)
end

include("parser/test.jl")
include("strips/test.jl")
include("typing/test.jl")
include("axioms/test.jl")
include("adl/test.jl")
include("numeric/test.jl")
include("constants/test.jl")
include("arrays/test.jl")
include("sets/test.jl")
include("functions/test.jl")
