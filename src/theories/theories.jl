# Theories for data types

"""
    valterm(val)

Express `val` as a `Term` based on its type. Wraps `val` in `Const` by default.
"""
valterm(val) = Const(val)

"Generate expression to register definitions in a theory module."
function register_theory_expr(theory::Module)
    expr = Expr(:block)
    for (name, ty) in theory.DATATYPES
        push!(expr.args, _register(:datatype, name, QuoteNode(ty)))
    end
    for (name, f) in theory.PREDICATES
        push!(expr.args, _register(:predicate, name, QuoteNode(f)))
    end
    for (name, f) in theory.FUNCTIONS
        push!(expr.args, _register(:function, name, QuoteNode(f)))
    end
    push!(expr.args, nothing)
    return expr
end

"Runtime registration of the definitions in a theory module."
function register_theory!(theory::Module)
    for (name, ty) in theory.DATATYPES
        PDDL.register!(:datatype, name, ty)
    end
    for (name, f) in theory.PREDICATES
        PDDL.register!(:predicate, name, f)
    end
    for (name, f) in theory.FUNCTIONS
        PDDL.register!(:function, name, f)
    end
    return nothing
end

"Runtime deregistration of the definitions in a theory module."
function deregister_theory!(theory::Module)
    for (name, ty) in theory.DATATYPES
        PDDL.deregister!(:datatype, name)
    end
    for (name, f) in theory.PREDICATES
        PDDL.deregister!(:predicate, name)
    end
    for (name, f) in theory.FUNCTIONS
        PDDL.deregister!(:function, name)
    end
    return nothing
end

"Attach a custom theory to a PDDL domain."
function attach_theory!(domain::Domain, theory::Module)
    for (name, ty) in theory.DATATYPES
        PDDL.attach!(domain, :datatype, name, ty)
    end
    for (name, f) in theory.PREDICATES
        PDDL.attach!(domain, :function, name, f)
    end
    for (name, f) in theory.FUNCTIONS
        PDDL.attach!(domain, :function, name, f)
    end
    return nothing
end

# Array-valued fluents
include("arrays.jl")
# Set-valued fluents
include("sets.jl")
