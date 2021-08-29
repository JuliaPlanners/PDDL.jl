abstract type CompiledDomain <: Domain end

abstract type CompiledState <: State end

abstract type CompiledAction <: Action end

include("domain.jl")
include("state.jl")
include("action.jl")

include("objects.jl")
include("accessors.jl")
include("formulas.jl")

include("satisfy.jl")
include("evaluate.jl")
include("initstate.jl")
include("transition.jl")
include("available.jl")
include("execute.jl")

function pddl_to_type_name(name)
    words = split(lowercase(string(name)), '-', keepempty=false)
    return join(uppercasefirst.(words))
end

function compiled(domain::Domain, state::State)
    # Generate definitions
    domain_type, domain_typedef, domain_defs =
        generate_domain_type(domain, state)
    state_type, state_typedef, state_defs =
        generate_state_type(domain, state, domain_type)
    initstate_def =
        generate_initstate(domain, state, domain_type, state_type)
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
    problem = GenericProblem(state)
    return_expr =
        :($domain_type(), initstate($domain_type(), $(QuoteNode(problem))))
    # Evaluate definitions
    expr = Expr(:block,
        domain_typedef, domain_defs, state_typedef, state_defs, initstate_def,
        object_defs, evaluate_def, satisfy_def, action_defs, transition_def,
        return_expr)
    return eval(expr)
end

function compiled(domain::Domain, problem::Problem)
    return compiled(domain, initstate(domain, problem))
end
