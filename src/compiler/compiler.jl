
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

!!! warning "Top-Level Only"
    Because `compiled` defines new types and methods, it should only be
    called at the top-level in order to avoid world-age errors.

!!! warning "Precompilation Not Supported"
    Because `compiled` evaluates code in the `PDDL` module, it will lead to
    precompilation errors when used in another module or package. Modules
    which call `compiled` should hence disable precompilation.
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
    # Generate warm-up and return expressions
    warmup_expr = :(_compiler_warmup($domain_type(), $state_type($state)))
    return_expr = :($domain_type(), $state_type($state))
    # Evaluate definitions
    expr = Expr(:block,
        domain_typedef, domain_defs, state_typedef, state_defs, object_defs,
        evaluate_def, satisfy_def, action_defs, transition_def,
        warmup_expr, return_expr)
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

"Warm up interface functions for a compiled domain and state."
function _compiler_warmup(domain::CompiledDomain, state::CompiledState)
    # Warm up state constructors and accessors
    hash(state)
    copy(state)
    state == state
    term = first(get_fluent_names(state))
    state[term] = state[term]
    # Warm up satisfy and evaluate
    for term in get_fluent_names(state)
        is_pred(term, domain) || continue
        satisfy(domain, state, term)
        evaluate(domain, state, term)
        break
    end
    # Warm up action availability, execution, and state transition
    available(domain, state)
    for (name, act) in pairs(get_actions(domain))
        all_args = groundargs(domain, state, act)
        isempty(all_args) && continue
        args = first(all_args)
        term = Compound(name, collect(Term, args))
        if available(domain, state, term)
            execute!(domain, copy(state), term)
            execute(domain, state, term)
            transition!(domain, copy(state), term)
            transition(domain, state, term)
        end
    end
    return nothing
end
