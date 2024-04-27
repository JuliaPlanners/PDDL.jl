# Theories for data types

"Generate expression to register definitions in a theory module."
function register_theory_expr(theory::Module)
    expr = Expr(:block)
    for (name, ty) in theory.DATATYPES
        push!(expr.args, register_expr(:datatype, name, QuoteNode(ty)))
    end
    for (name, ty) in theory.ABSTRACTIONS
        push!(expr.args, register_expr(:abstraction, name, QuoteNode(ty)))
    end
    for (name, ty) in theory.CONVERTERS
        push!(expr.args, register_expr(:converter, name, QuoteNode(ty)))
    end
    for (name, f) in theory.PREDICATES
        push!(expr.args, register_expr(:predicate, name, QuoteNode(f)))
    end
    for (name, f) in theory.FUNCTIONS
        push!(expr.args, register_expr(:function, name, QuoteNode(f)))
    end
    push!(expr.args, nothing)
    return expr
end

"Runtime registration of the definitions in a theory module."
function register_theory!(theory::Module)
    for (name, ty) in theory.DATATYPES
        PDDL.register!(:datatype, name, ty)
    end
    for (name, ty) in theory.ABSTRACTIONS
        PDDL.register!(:abstraction, name, ty)
    end
    for (name, ty) in theory.CONVERTERS
        PDDL.register!(:converter, name, ty)
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
    for (name, ty) in theory.ABSTRACTIONS
        PDDL.deregister!(:abstraction, name)
    end
    for (name, ty) in theory.CONVERTERS
        PDDL.deregister!(:converter, name)
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

"""
    @pddltheory module M ... end

Declares a module `M` as a PDDL theory. This defines the `M.@register`,
`M.register!`, `M.deregister!` and `M.attach!` functions automatically.
"""
macro pddltheory(module_expr)
    if !Meta.isexpr(module_expr, :module)
        error("Only `module` expressions can be declared as PDDL theories.")
    end
    autodefs = quote
        macro register()
            return $(GlobalRef(PDDL, :register_theory_expr))(@__MODULE__)
        end
        function register!()
            return $(GlobalRef(PDDL, :register_theory!))(@__MODULE__)
        end
        function deregister!()
            return $(GlobalRef(PDDL, :deregister_theory!))(@__MODULE__)
        end
        function attach!(domain::$(GlobalRef(PDDL, :Domain)))
            return $(GlobalRef(PDDL, :attach_theory!))(domain, @__MODULE__)
        end
    end
    module_block = module_expr.args[3]
    append!(module_block.args, autodefs.args)
    return esc(module_expr)
end

# Array-valued fluents
include("arrays.jl")
# Set-valued fluents
include("sets.jl")
