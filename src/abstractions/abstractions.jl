# Semantics for abstract values #

"Compute least upper bound (i.e. join) of two abstract values."
function lub end

"Compute greatest lower bound (i.e. meet) of two abstract values."
function glb end

"Compute widening of two abstract values."
function widen end

include("boolean.jl")
include("interval.jl")
