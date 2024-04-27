# Semantics for abstract values #

"""
    lub(a, b)

Compute the least upper bound (i.e. join) of abstract values `a` and `b`.

    lub(T, iter)

Compute the least upper bound (i.e. join) of abstract values in `iter`, assuming
that all values in `iter` are of type `T`.
"""
function lub end

"""
    glb(a, b)

Compute the greatest lower bound (i.e. meet) of abstract values `a` and `b`.

    glb(T, iter)

Compute the greatest lower bound (i.e. meet) of abstract values in `iter`,
assuming that all values in `iter` are of type `T`.
"""
function glb end

"""
    widen(a, b)

Compute the widening of abstract values `a` and `b`.
"""
function widen end

include("boolean.jl")
include("interval.jl")
include("set.jl")

"""
$(SIGNATURES)

Mapping from PDDL types to default abstraction types.
"""
@valsplit default_abstype(Val(name::Symbol)) =
    error("Unknown datatype: $name")

default_abstype(::Val{:boolean}) = BooleanAbs
default_abstype(::Val{:integer}) = IntervalAbs{Int}
default_abstype(::Val{:number}) = IntervalAbs{Float64}
default_abstype(::Val{:numeric}) = IntervalAbs{Float64}

"""
$(SIGNATURES)

Return list of datatypes with default abstractions defined for them.
"""
default_abstype_names() =
    valarg_params(default_abstype, Tuple{Val}, Val(1), Symbol)

"""
$(SIGNATURES)

Return dictionary mapping datatype names to default abstraction types.
"""
function default_abstypes()
    names = default_abstype_names()
    types = Base.to_tuple_type(default_abstype.(names))
    return _generate_dict(Val(names), Val(types))
end
