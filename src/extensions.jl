"""
    register!([:datatype|:predicate|:function|:modifier], name, x)

Register `x` as a global datatype, predicate, function or modifier under
the specified `name`.
"""
function register!(category::Symbol, name::Symbol, x)
    if category == :datatype
        register_datatype!(name, x)
    elseif category == :predicate
        register_predicate!(name, x)
    elseif category == :function
        register_function!(name, x)
    elseif category == :modifier
        register_modifier!(name, x)
    else
        error("Category must be :datatype, :predicate, :function or :modifier.")
    end
end

register!(category::Symbol, name::AbstractString, x) =
    register!(category, Symbol(name), x)

"Register global datatype."
function register_datatype!(name::Symbol, ty)
    _datatype_def = GlobalRef(@__MODULE__, :datatype_def)
    @eval $_datatype_def(::Val{$(QuoteNode(name))}) = $(QuoteNode(ty))
end

"Register global predicate."
function register_predicate!(name::Symbol, f)
    _predicate_def = GlobalRef(@__MODULE__, :predicate_def)
    @eval $_predicate_def(::Val{$(QuoteNode(name))}) = $(QuoteNode(f))
end

"Register global function."
function register_function!(name::Symbol, f)
    _function_def = GlobalRef(@__MODULE__, :function_def)
    @eval $_function_def(::Val{$(QuoteNode(name))}) = $(QuoteNode(f))
end

"Register global modifier."
function register_modifier!(name::Symbol, f)
    _modifier_def = GlobalRef(@__MODULE__, :modifier_def)
    @eval $_modifier_def(::Val{$(QuoteNode(name))}) = $(QuoteNode(f))
end

"""
    deregister!([:datatype|:predicate|:function|:modifier], name)

Deregister the datatype, predicate, function or modifier specified by `name`.
"""
function deregister!(category::Symbol, name::Symbol)
    if category == :datatype
        deregister_datatype!(name)
    elseif category == :predicate
        deregister_predicate!(name)
    elseif category == :function
        deregister_function!(name)
    elseif category == :modifier
        deregister_modifier!(name)
    else
        error("Category must be :datatype, :predicate, :function or :modifier.")
    end
end

deregister!(category::Symbol, name::AbstractString) =
    deregister!(category, Symbol(name))

"Deregister global datatype."
function deregister_datatype!(name::Symbol)
    if hasmethod(datatype_def, Tuple{Val{name}})
        m = first(methods(datatype_def, Tuple{Val{name}}))
        Base.delete_method(m)
    else
        @warn "No registered datatype :$name to deregister."
    end
end

"Deregister global predicate."
function deregister_predicate!(name::Symbol)
    if hasmethod(predicate_def, Tuple{Val{name}})
        m = first(methods(predicate_def, Tuple{Val{name}}))
        Base.delete_method(m)
    else
        @warn "No registered predicate :$name to deregister."
    end
end

"Deregister global function."
function deregister_function!(name::Symbol)
    if hasmethod(function_def, Tuple{Val{name}})
        m = first(methods(function_def, Tuple{Val{name}}))
        Base.delete_method(m)
    else
        @warn "No registered predicate :$name to deregister."
    end
end

"Deregister global modifier."
function deregister_modifier!(name::Symbol)
    if hasmethod(modifier_def, Tuple{Val{name}})
        m = first(methods(modifier_def, Tuple{Val{name}}))
        Base.delete_method(m)
    else
        @warn "No registered predicate :$name to deregister."
    end
end

"""
    attach!(domain, :function, name, f)

Attach the function `f` as the implementation of the functional fluent
specified by `name`.

    attach!(domain, :datatype, name, ty)

Attach the type `ty` as the implementation of the PDDL datatype
specified by `name`.
"""
function attach!(domain::GenericDomain, category::Symbol, name::Symbol, f)
    if category == :datatype
        attach_datatype!(domain, name, f)
    elseif category == :function
        attach_function!(domain, name, f)
    else
        error("Category must be :datatype or :function.")
    end
end
attach!(domain::GenericDomain, category::Symbol, name::AbstractString, f) =
    attach!(domain, category, Symbol(name), f)

"Attach datatype to domain."
function attach_datatype!(domain::GenericDomain, name::Symbol, ty)
    domain.datatypes[name] = ty
end

"Attach function to domain."
function attach_function!(domain::GenericDomain, name::Symbol, f)
    if name in keys(get_functions(domain))
        domain.funcdefs[name] = f
    else
        error("Domain does not have a function named $name.")
    end
end
