# Theories for data types

"""
    valterm(val)

Express `val` as a `Term` based on its type. Wraps `val` in `Const` by default.
"""
valterm(val) = Const(val)

# Array-valued fluents
include("arrays.jl")
# Set-valued fluents
include("sets.jl")
