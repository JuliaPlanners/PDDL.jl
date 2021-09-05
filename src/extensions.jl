"""
    register!([:predicate|:function|:modifier], name, f)

Register the function `f` as a global predicate, function or modifier under
the specified `name`.
"""
function register!(category::Symbol, name::Symbol, f)
    if category == :predicate
        register_predicate!(name, f)
    elseif category == :function
        register_function!(name, f)
    elseif category == :modifier
        register_modifier!(name, f)
    else
        error("Category must be :predicate, :function or :modifier.")
    end
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
