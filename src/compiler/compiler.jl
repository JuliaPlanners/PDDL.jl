
abstract type CompiledAction <: Action end

# Utility functions
include("utils.jl")
# Compiled types
include("domain.jl")
include("state.jl")
include("action.jl")
# Helper functions for objects/accessors/formulas
include("objects.jl")
include("accessors.jl")
include("formulas.jl")
# Interface functions
include("satisfy.jl")
include("evaluate.jl")
include("initstate.jl")
include("transition.jl")
include("available.jl")
include("execute.jl")

"""
    compiled(domain, state)
    compiled(domain, problem)

Compile a `domain` and `state` and return the resulting compiled domain
and compiled state. A `problem` maybe provided instead of a state.
Note that this function must be called at the top-level in order to avoid
world-age errors.
"""
function compiled(domain::Domain, state::State)
    # Generate definitions
    domain_type, domain_typedef, domain_defs =
        generate_domain_type(domain, state)
    state_type, state_typedef, state_defs =
        generate_state_type(domain, state, domain_type)
    object_defs =
        generate_object_defs(domain, state, domain_type, state_type)
    evaluate_def =
        generate_evaluate(domain, state, domain_type, state_type)
    satisfy_def =
        generate_satisfy(domain, state, domain_type, state_type)
    action_defs =
        generate_action_defs(domain, state, domain_type, state_type)
    transition_def =
        generate_transition(domain, state, domain_type, state_type)
    # Generate return expression
    return_expr = :($domain_type(), $state_type($state))
    # Evaluate definitions
    expr = Expr(:block,
        domain_typedef, domain_defs, state_typedef, state_defs, object_defs,
        evaluate_def, satisfy_def, action_defs, transition_def, return_expr)
    return eval(expr)
end

function compiled(domain::Domain, problem::Problem)
    return compiled(domain, initstate(domain, problem))
end

"""
    compilestate(domain, state)

Return compiled version of a state compatible with the compiled `domain`.
"""
function compilestate(domain::CompiledDomain, state::State)
    S = statetype(domain)
    return S(state)
end

# Abstract a domain that is already compiled
function abstracted(domain::CompiledDomain, state::State; options...)
    absdom = abstracted(get_source(domain); options...)
    return compiled(absdom, GenericState(state))
end

# If compiled state is abstract, we can just copy construct
function abstractstate(domain::CompiledDomain, state::State)
    S = statetype(domain)
    return S(state)
end
