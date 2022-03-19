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

"Mapping from PDDL data types to Julia types and default values."
@valsplit datatype_def(Val(name::Symbol)) =
    error("Unknown datatype: $name")
datatype_def(::Val{:boolean}) = (type=Bool, default=false)
datatype_def(::Val{:integer}) = (type=Int, default=0)
datatype_def(::Val{:numeric}) = (type=Float64, default=0.0)

"Return list of global datatypes."
global_datatype_names() =
    valarg_params(datatype_def, Tuple{Val}, Val(1), Symbol)
"Return dictionary mapping global datatype names to implementations."
global_datatypes() =
    Dict{Symbol,Any}(d => datatype_def(Val(d)) for d in global_datatype_names())
"Return whether a symbol refers to global datatype."
is_global_datatype(name::Symbol) =
    valarg_has_param(name, datatype_def, Tuple{Val}, Val(1), Symbol)

"Mapping from PDDL built-in predicates to Julia functions."
@valsplit predicate_def(Val(name::Symbol)) =
    error("Unknown predicate or function: $name")
predicate_def(::Val{:(==)}) = equiv
predicate_def(::Val{:<=}) = <=
predicate_def(::Val{:>=}) = >=
predicate_def(::Val{:<}) = <
predicate_def(::Val{:>}) = >

"Return list of all global predicate names."
global_predicate_names() =
    valarg_params(predicate_def, Tuple{Val}, Val(1), Symbol)
"Return dictionary mapping global predicate names to implementations."
global_predicates() =
    Dict{Symbol,Any}(p => predicate_def(p) for p in global_predicate_names())
"Return whether a symbol refers to global predicate."
is_global_pred(name::Symbol) =
    valarg_has_param(name, predicate_def, Tuple{Val}, Val(1), Symbol)

"Mapping from PDDL built-in functions to Julia functions."
@valsplit function_def(Val(name::Symbol)) =
    predicate_def(name) # All predicates are also functions
function_def(::Val{:+}) = +
function_def(::Val{:-}) = -
function_def(::Val{:*}) = *
function_def(::Val{:/}) = /

"Return list of all global function names."
global_function_names() =
    (valarg_params(function_def, Tuple{Val}, Val(1), Symbol)...,
     valarg_params(predicate_def, Tuple{Val}, Val(1), Symbol)...)
"Return dictionary mapping global function names to implementations."
global_functions() =
    Dict{Symbol,Any}(f => function_def(f) for f in global_function_names())
"Return whether a symbol refers to global function."
is_global_func(name::Symbol) =
    valarg_has_param(name, function_def, Tuple{Val}, Val(1), Symbol) ||
    is_global_pred(name)

"Mapping from PDDL modifiers (i.e. in-place assignments) to PDDL functions."
@valsplit modifier_def(Val(name::Symbol)) =
    error("Unknown modifier: $name")
modifier_def(::Val{:increase}) = :+
modifier_def(::Val{:decrease}) = :-
modifier_def(::Val{Symbol("scale-up")}) = :*
modifier_def(::Val{Symbol("scale-down")}) = :/

"Return list of all global modifier names."
global_modifier_names() =
    (valarg_params(modifier_def, Tuple{Val}, Val(1), Symbol)...,
     valarg_params(predicate_def, Tuple{Val}, Val(1), Symbol)...)
"Return dictionary mapping global modifier names to implementations."
global_modifiers() =
    Dict{Symbol,Any}(m => modifier_def(m) for m in global_modifier_names())
"Return whether a symbol refers to global modifier."
is_global_modifier(name::Symbol) =
    valarg_has_param(name, modifier_def, Tuple{Val}, Val(1), Symbol)
