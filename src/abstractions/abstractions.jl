# Semantics for abstract values #

"""
    lub(a, b)

Compute the least upper bound (i.e. join) of abstract values `a` and `b`.
"""
function lub end

"""
    glb(a, b)

Compute the greatest lower bound (i.e. meet) of abstract values `a` and `b`.
"""
function glb end

"""
    widen(a, b)

Compute the widening of abstract values `a` and `b`.
"""
function widen end

include("boolean.jl")
include("interval.jl")
