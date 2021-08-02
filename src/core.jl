# Core functions for evaluating PDDL formulae and state transitions

function satisfy(domain::GenericDomain, state::GenericState,
                 terms::AbstractVector{<:Term})
    # Do quick check as to whether formulae are in the set of facts
    function in_facts(f::Term)
        if !isempty(state.fluents)
            f = eval_term(f, Subst(), state.fluents) end
        if f in state.facts || f in state.types
            return true end
        if !isnothing(domain) && f in get_const_facts(domain)
            return true end
        if f.name in Julog.comp_ops || f.name in keys(state.fluents)
            return eval_term(f, Subst(), state.fluents).name == true end
        return false
    end
    if all(f -> f.name == :not ? !in_facts(f.args[1]) : in_facts(f), terms)
        return true end
    # Initialize Julog knowledge base
    clauses = Clause[get_clauses(domain);
                     collect(state.types); collect(state.facts)]
    # Pass in fluents and function definitions as a dictionary of functions
    funcs = merge(state.fluents, domain.funcdefs)
    return resolve(collect(terms), clauses; funcs=funcs, mode=:any)[1]
end

satisfy(domain::GenericDomain, state::GenericState, term::Term) =
    satisfy(domain, state, [term])

function satisfiers(domain::GenericDomain, state::GenericState,
                    terms::AbstractVector{<:Term})
    # Initialize Julog knowledge base
    clauses = Clause[get_clauses(domain);
                     collect(state.types); collect(state.facts)]
    # Pass in fluents and function definitions as a dictionary of functions
    funcs = merge(state.fluents, domain.funcdefs)
    return resolve(collect(terms), clauses; funcs=funcs, mode=:all)[2]
end

satisfiers(domain::GenericDomain, state::GenericState, term::Term) =
    satisfiers(domain, state, [term])

function evaluate(domain::GenericDomain, state::GenericState, term::Term)
    # Evaluate formula as fully as possible
    funcs = merge(state.fluents, domain.funcdefs)
    val = eval_term(term, Subst(), funcs)
    # Return if formula evaluates to a Const (unwrapping if as_const=false)
    if isa(val, Const) && !isa(val.name, Symbol) return val.name end
    # If val is not a Const, check if holds true in the state
    return satisfy(domain, state, val)
end

"""
    find_matches(term, state, domain=nothing)

Returns a list of all matching substitutions of `term` with respect to
a given `state` and `domain`.
"""
function find_matches(domain::GenericDomain, state::GenericState, term::Term)
    if term.name in keys(state.fluents)
        clauses = Vector{Clause}(get_fluents(state))
        _, subst = resolve(term, clauses; mode=:all)
    else
        clauses = isnothing(domain) ? Clause[] : get_clauses(domain)
        clauses = Clause[clauses; collect(state.types); collect(state.facts)]
        funcs = state.fluents
        _, subst = resolve(term, clauses; funcs=funcs, mode=:all)
    end
    matches = Term[substitute(term, s) for s in subst]
    return matches
end

"Construct initial state from problem definition."
function init_state(problem::GenericProblem)
    types = Term[@julog($ty(:o)) for (o, ty) in problem.objtypes]
    state = GenericState(problem.init, types)
    return state
end

"Construct goal state from problem definition."
function goal_state(problem::GenericProblem)
    types = Term[@julog($ty(:o)) for (o, ty) in problem.objtypes]
    state = GenericState(flatten_conjs(problem.goal), types)
    return state
end

"Construct initial state from problem definition."
initialize(problem::GenericProblem) = init_state(problem)

function transition(domain::GenericDomain, state::GenericState, action::Term;
                    check::Bool=true, fail_mode::Symbol=:error)
    state = execute(domain, state, action; check=check, fail_mode=fail_mode)
    if length(domain.events) > 0
        state = trigger(domain, state, domain.events)
    end
    return state
end

"""
    simulate(domain, state, actions; kwargs...)

Returns the state trajectory that results from applying a sequence of `actions`
to an initial `state` in a given `domain`. Keyword arguments specify whether
to `check` if action preconditions hold, the `fail_mode` (`:error` or `:no_op`)
if they do not, and a `callback` function to apply after each step.
"""
function simulate(domain::GenericDomain, state::GenericState,
                  actions::AbstractVector{<:Term};
                  check::Bool=true, fail_mode::Symbol=:error, callback=nothing)
    trajectory = GenericState[state]
    if callback !== nothing callback(domain, state, Const(:start)) end
    for act in actions
        state = transition(domain, state, act; check=check, fail_mode=fail_mode)
        push!(trajectory, state)
        if callback !== nothing callback(domain, state, act) end
    end
    return trajectory
end
