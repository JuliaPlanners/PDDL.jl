# Core functions for evaluating PDDL formulae and state transitions

"""
    satisfy(formulae, state, domain=nothing; mode=:any)

Returns whether `formulae` can be satisfied by facts in the given `state`,
and any axioms / derived predicates in `domain`. If `formulae` contains
unbound variables, `mode=:any` returns the first substitution found,
while `mode=:all` returns all substitutions.
"""
function satisfy(formulae::Vector{<:Term}, state::State,
                 domain::Union{Domain,Nothing}=nothing; mode::Symbol=:any)
    # Do quick check as to whether formulae are in the set of facts
    function in_facts(f::Term)
        if !isempty(state.fluents)
            f = eval_term(f, Subst(), state.fluents) end
        if f in state.facts || f in state.types
            return true end
        if domain != nothing && f in get_const_facts(domain)
            return true end
        if f.name in Julog.comp_ops || f.name in keys(state.fluents)
            return eval_term(f, Subst(), state.fluents).name == true end
        return false
    end
    if all(f -> f.name == :not ? !in_facts(f.args[1]) : in_facts(f), formulae)
        return true, [Subst()] end
    # Initialize Julog knowledge base
    clauses = domain == nothing ? Clause[] : get_clauses(domain)
    clauses = Clause[clauses; collect(state.types); collect(state.facts)]
    # Pass in fluents as a dictionary of functions
    funcs = state.fluents
    return resolve(formulae, clauses; funcs=funcs, mode=mode)
end

satisfy(formula::Term, state::State, domain::Union{Domain,Nothing}=nothing;
        options...) = satisfy(Term[formula], state, domain; options...)

"""
    evaluate(formula, state, domain=nothing; as_const=true)

Evaluates `formula` as fully as possible with respect to the fluents defined
in `state`, along with any axioms / derived predicates defined in `domain`.
Returns a Julog `Const` if `as_const=true`, otherwise return an unwrapped
Julia value.
"""
function evaluate(formula::Term, state::State,
                  domain::Union{Domain,Nothing}=nothing; as_const::Bool=true)
    # Evaluate formula as fully as possible
    val = eval_term(formula, Subst(), state.fluents)
    # Return if formula evaluates to a Const (unwrapping if as_const=false)
    if isa(val, Const) && !isa(val.name, Symbol)
        return as_const ? val : val.name end
    # If val is not a Const, check if holds true in the state
    sat, _ = satisfy(Term[val], state, domain)
    return as_const ? Const(sat) : sat # Wrap in Const if as_const=true
end

"""
    find_matches(formula, state, domain=nothing)

Returns a list of all matching substitutions of `formula` with respect to
a given `state` and `domain`.
"""
function find_matches(formula::Term, state::State,
                      domain::Union{Domain,Nothing}=nothing)
    if formula.name in keys(state.fluents)
        clauses = Vector{Clause}(get_fluents(state))
        _, subst = resolve(formula, clauses; mode=:all)
    else
        clauses = domain == nothing ? Clause[] : get_clauses(domain)
        clauses = Clause[clauses; collect(state.types); collect(state.facts)]
        funcs = state.fluents
        _, subst = resolve(formula, clauses; funcs=funcs, mode=:all)
    end
    matches = Term[substitute(formula, s) for s in subst]
    return matches
end

"Create initial state from problem definition."
function initialize(problem::Problem)
    types = Term[@julog($ty(:o)) for (o, ty) in problem.objtypes]
    state = State(problem.init, types)
    return state
end

"""
    transition(domain, state, action::Term; kwargs...)
    transition(domain, state, actions::Set{<:Term}; kwargs...)

Returns the successor to `state` in the given `domain` after applying a single
`action` or a set of `actions` in parallel, along with any events triggered
by the effects of those actions. Keyword arguments specify whether to `check`
if action preconditions hold, and the `fail_mode` (`:error` or `:no_op`)
if they do not.
"""
function transition(domain::Domain, state::State, action::Term;
                    check::Bool=true, fail_mode::Symbol=:error)
    state = execute(action, state, domain; check=check, fail_mode=fail_mode)
    if length(domain.events) > 0
        state = trigger(domain.events, state, domain)
    end
    return state
end

function transition(domain::Domain, state::State, actions::Set{<:Term};
                    check::Bool=true, fail_mode::Symbol=:error)
    # Execute all actions in parallel
    state = execpar(actions, state, domain, check=check, fail_mode=fail_mode)
    if length(domain.events) > 0
        state = trigger(domain.events, state, domain)
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
function simulate(domain::Domain, state::State, actions::Vector{<:Term};
                  check::Bool=true, fail_mode::Symbol=:error,
                  callback::Function=(d,s,a)->nothing)
    trajectory = State[state]
    callback(domain, state, Const(:start))
    for act in actions
        state = transition(domain, state, act; check=check, fail_mode=fail_mode)
        push!(trajectory, state)
        callback(domain, state, act)
    end
    return trajectory
end

function simulate(domain::Domain, state::State, actions::Vector{Set{<:Term}};
                  check::Bool=true, fail_mode::Symbol=:error,
                  callback::Function=(d,s,a)->nothing)
    trajectory = State[state]
    callback(domain, state, Set([Const(:start)]))
    for acts in actions
        state = transition(domain, state, acts;
                           check=check, fail_mode=fail_mode)
        push!(trajectory, state)
        callback(domain, state, acts)
    end
    return trajectory
end
