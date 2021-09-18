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
    GLOBAL_DATATYPES[name] = ty
end

"Register global predicate."
function register_predicate!(name::Symbol, f)
    GLOBAL_PREDICATES[name] = f
    GLOBAL_FUNCTIONS[name] = f
end

"Register global function."
function register_function!(name::Symbol, f)
    GLOBAL_FUNCTIONS[name] = f
end

"Register global modifier."
function register_modifier!(name::Symbol, f)
    GLOBAL_MODIFIERS[name] = f
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
    delete!(GLOBAL_DATATYPES, name)
end

"Deregister global predicate."
function deregister_predicate!(name::Symbol)
    delete!(GLOBAL_FUNCTIONS, name)
    delete!(GLOBAL_PREDICATES, name)
end

"Deregister global function."
function deregister_function!(name::Symbol)
    delete!(GLOBAL_PREDICATES, name)
    delete!(GLOBAL_FUNCTIONS, name)
end

"Deregister global modifier."
function deregister_modifier!(name::Symbol)
    delete!(GLOBAL_MODIFIERS, name)
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
attach!(domain::GenericDomain, name::AbstractString, f) =
    attach!(domain, Symbol(name), f)

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
