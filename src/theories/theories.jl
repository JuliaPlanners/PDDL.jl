# Theories for data types

"""
    defaultval(::Val{T})

Returns the default value for a PDDL datatype `T` specified as a `Symbol`.
"""
function defaultval end

# Default values for built-in datatypes
defaultval(::Val{:boolean}) = false
defaultval(::Val{:integer}) = 0
defaultval(::Val{:numeric}) = 0.0

"""
    valterm(val)

Express `val` as a `Term` based on its type. Wraps `val` in `Const` by default.
"""
valterm(val) = Const(val)

# Array-valued fluents
include("arrays.jl")
# Set-valued fluents
include("sets.jl")
