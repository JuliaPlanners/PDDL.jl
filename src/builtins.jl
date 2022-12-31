# Built in operators, functions, and effects

"""
    equiv(a, b)

Equivalence in concrete and abstract domains. Defaults to `a == b`.
"""
equiv(a, b) = a == b

"""
    nequiv(a, b)

Non-equivalence in concrete and abstract domains. Defaults to `a != b`.
"""
nequiv(a, b) = a != b

"""
    val_to_term(datatype::Symbol, val)
    val_to_term(val)

Express `val` as a `Term` based on the `datatype`. Wraps in `Const` by default.
If `datatype` is unspecified, it will be inferred.
"""
@valsplit val_to_term(Val(datatype::Symbol), val) = val_to_term(nothing, val)
val_to_term(datatype::Nothing, val) = Const(val)
val_to_term(val::T) where {T} = val_to_term(infer_datatype(T), val)

"""
$(SIGNATURES)

Mapping from PDDL data types to Julia types and default values.
"""
@valsplit datatype_def(Val(name::Symbol)) =
    error("Unknown datatype: $name")
datatype_def(::Val{:boolean}) = (type=Bool, default=false)
datatype_def(::Val{:integer}) = (type=Int, default=0)
datatype_def(::Val{:numeric}) = (type=Float64, default=1.0)

"""
$(SIGNATURES)

Mapping from PDDL datatype to Julia type.
"""
datatype_typedef(name::Symbol) = datatype_def(name).type
"""
$(SIGNATURES)

Mapping from PDDL datatype to default value.
"""
datatype_default(name::Symbol) = datatype_def(name).default

"""
$(SIGNATURES)

Return list of global datatypes.
"""
global_datatype_names() =
    valarg_params(datatype_def, Tuple{Val}, Val(1), Symbol)
"""
$(SIGNATURES)

Return whether a symbol refers to global datatype.
"""
is_global_datatype(name::Symbol) =
    valarg_has_param(name, datatype_def, Tuple{Val}, Val(1), Symbol)
"""
$(SIGNATURES)

Return dictionary mapping global datatype names to implementations.
"""
function global_datatypes()
    names = global_datatype_names()
    types = Base.to_tuple_type(getindex.(datatype_def.(names), 1))
    return _generate_dict(Val(names), Val(types))
end

"""
$(SIGNATURES)

Infer PDDL datatype from Julia type.
"""
function infer_datatype(T::Type)
    inferred = nothing
    mintype = Any
    for (name, type) in global_datatypes()
        if T <: type <: mintype
            inferred = name
            mintype = type
        end
    end
    return inferred
end
infer_datatype(val::T) where {T} = infer_datatype(T)

"""
$(SIGNATURES)

Mapping from PDDL built-in predicates to Julia functions.
"""
@valsplit predicate_def(Val(name::Symbol)) =
    error("Unknown predicate or function: $name")
predicate_def(::Val{:(==)}) = equiv
predicate_def(::Val{:<=}) = <=
predicate_def(::Val{:>=}) = >=
predicate_def(::Val{:<}) = <
predicate_def(::Val{:>}) = >

"""
$(SIGNATURES)

Return list of all global predicate names.
"""
global_predicate_names() =
    valarg_params(predicate_def, Tuple{Val}, Val(1), Symbol)
"""
$(SIGNATURES)

Return whether a symbol refers to global predicate.
"""
is_global_pred(name::Symbol) =
    valarg_has_param(name, predicate_def, Tuple{Val}, Val(1), Symbol)
"""
$(SIGNATURES)

Return dictionary mapping global predicate names to implementations.
"""
function global_predicates()
    names = global_predicate_names()
    defs = predicate_def.(names)
    return _generate_dict(Val(names), Val(defs))
end

"""
$(SIGNATURES)

Mapping from PDDL built-in functions to Julia functions.
"""
@valsplit function_def(Val(name::Symbol)) =
    predicate_def(name) # All predicates are also functions
function_def(::Val{:+}) = +
function_def(::Val{:-}) = -
function_def(::Val{:*}) = *
function_def(::Val{:/}) = /

"""
$(SIGNATURES)

Return list of all global function names.
"""
global_function_names() =
    (valarg_params(function_def, Tuple{Val}, Val(1), Symbol)...,
     valarg_params(predicate_def, Tuple{Val}, Val(1), Symbol)...)
"""
$(SIGNATURES)

Return whether a symbol refers to global function.
"""
is_global_func(name::Symbol) =
    valarg_has_param(name, function_def, Tuple{Val}, Val(1), Symbol) ||
    is_global_pred(name)
"""
$(SIGNATURES)

Return dictionary mapping global function names to implementations.
"""
function global_functions()
    names = global_function_names()
    defs = function_def.(names)
    return _generate_dict(Val(names), Val(defs))
end

"""
$(SIGNATURES)

Mapping from PDDL modifiers (i.e. in-place assignments) to PDDL functions.
"""
@valsplit modifier_def(Val(name::Symbol)) =
    error("Unknown modifier: $name")
modifier_def(::Val{:increase}) = :+
modifier_def(::Val{:decrease}) = :-
modifier_def(::Val{Symbol("scale-up")}) = :*
modifier_def(::Val{Symbol("scale-down")}) = :/

"""
$(SIGNATURES)

Return list of all global modifier names.
"""
global_modifier_names() =
    valarg_params(modifier_def, Tuple{Val}, Val(1), Symbol)
"""
$(SIGNATURES)

Return whether a symbol refers to global modifier.
"""
is_global_modifier(name::Symbol) =
    valarg_has_param(name, modifier_def, Tuple{Val}, Val(1), Symbol)
"""
$(SIGNATURES)

Return dictionary mapping global modifier names to implementations.
"""
function global_modifiers()
    names = global_modifier_names()
    defs = modifier_def.(names)
    return _generate_dict(Val(names), Val(defs))
end

"Helper function that generates dictionary at compile time."
@generated function _generate_dict(keys::Val{Ks}, values::Val{Vs}) where {Ks, Vs}
    Vs = Vs isa Tuple ? Vs : Tuple(Vs.parameters) # Handle tuple types
    dict = Dict(zip(Ks, Vs))
    return :($dict)
end
