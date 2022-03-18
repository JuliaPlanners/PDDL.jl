"""
    @register([:datatype|:predicate|:function|:modifier], name, x)

Register `x` as a global datatype, predicate, function or modifier under
the specified `name`.
"""
macro register(category, name, x)
    return _register(category, name, x)
end

function _register(category::Symbol, name::Symbol, x)
    if category == :datatype
        fname = GlobalRef(@__MODULE__, :datatype_def)
    elseif category == :predicate
        fname = GlobalRef(@__MODULE__, :predicate_def)
    elseif category == :function
        fname = GlobalRef(@__MODULE__, :function_def)
    elseif category == :modifier
        fname = GlobalRef(@__MODULE__, :modifier_def)
    else
        error("Category must be :datatype, :predicate, :function or :modifier.")
    end
    return :($fname(::Val{$(QuoteNode(name))}) = $(esc(x)))
end
_register(category::QuoteNode, name, x) =
    _register(category.value, name, x)
_register(category::Symbol, name::QuoteNode, x) =
    _register(category, name.value, x)
_register(category::Symbol, name::AbstractString, x) =
    _register(category, Symbol(name), x)

"""
    register!([:datatype|:predicate|:function|:modifier], name, x)

Register `x` as a global datatype, predicate, function or modifier under
the specified `name`.

!!! warning "Top-Level Only"
    Because `register!` defines new methods, it should only be called at the
    top-level in order to avoid world-age errors.

!!! warning "Precompilation Not Supported"
    Because `register!` evaluates code in the `PDDL` module, it will lead to
    precompilation errors when used in another module. For this reason, the
    `@register` macro is preferred, and this function should only be used in
    scripting contexts.
"""
function register!(category::Symbol, name::Symbol, x)
    if category == :datatype
        fname = GlobalRef(@__MODULE__, :datatype_def)
    elseif category == :predicate
        fname = GlobalRef(@__MODULE__, :predicate_def)
    elseif category == :function
        fname = GlobalRef(@__MODULE__, :function_def)
    elseif category == :modifier
        fname = GlobalRef(@__MODULE__, :modifier_def)
    else
        error("Category must be :datatype, :predicate, :function or :modifier.")
    end
    @eval $fname(::Val{$(QuoteNode(name))}) = $(QuoteNode(x))
end
register!(category::Symbol, name::AbstractString, x) =
    register!(category, Symbol(name), x)

"""
    deregister!([:datatype|:predicate|:function|:modifier], name)

Deregister the datatype, predicate, function or modifier specified by `name`.

!!! warning "Top-Level Only"
    Because `deregister!` deletes existing methods, it should only be called
    at the top-level in order to avoid world-age errors. It should primarily
    be used in scripting contexts, and not by other packages or modules.
"""
function deregister!(category::Symbol, name::Symbol)
    if category == :datatype
        f = datatype_def
    elseif category == :predicate
        f = predicate_def
    elseif category == :function
        f = function_def
    elseif category == :modifier
        f = modifier_def
    else
        error("Category must be :datatype, :predicate, :function or :modifier.")
    end
    if hasmethod(f, Tuple{Val{name}})
        m = first(methods(f, Tuple{Val{name}}))
        Base.delete_method(m)
    else
        @warn "No registered $f :$name to deregister."
    end
end

deregister!(category::Symbol, name::AbstractString) =
    deregister!(category, Symbol(name))

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
