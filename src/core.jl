# Core functions for evaluating PDDL formulae and state transitions

"Check whether formulas can be satisfied in a given state."
function satisfy(formulas::Vector{<:Term}, state::State,
                 domain::Union{Domain,Nothing}=nothing; mode::Symbol=:any)
    # Do quick check as to whether formulas are in the set of facts
    in_facts = all(formulas) do f
        if f in state.facts || f in state.types return true end
        if f.name == :not && !(f in state.facts) return true end
        if f.name in Julog.comp_ops || f.name in keys(state.fluents)
            return eval_term(f, Subst(), state.fluents).name == true end
        return false
    end
    if in_facts return true, Subst() end
    # Initialize Julog knowledge base
    clauses = domain == nothing ? Clause[] : get_clauses(domain)
    clauses = Clause[clauses; collect(state.types); collect(state.facts)]
    # Pass in fluents as a dictionary of functions
    funcs = state.fluents
    return resolve(formulas, clauses; funcs=funcs, mode=mode)
end

satisfy(formula::Term, state::State, domain::Union{Domain,Nothing}=nothing;
        options...) = satisfy(Term[formula], state, domain; options...)

"Evaluate formula within a given state."
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

"Find all matching formulae within a state."
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

"Simulate a single state transition (action + triggered events) in a domain."
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

"Simulate state trajectory for a given domain and sequence of actions."
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
