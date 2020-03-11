"Convert type hierarchy to list of Julog clauses."
function type_clauses(typetree::Dict{Symbol,Vector{Symbol}})
    clauses = [[Clause(@julog($ty(X)), Term[@julog($s(X))]) for s in subtys]
               for (ty, subtys) in typetree if length(subtys) > 0]
    return length(clauses) > 0 ? reduce(vcat, clauses) : Clause[]
end

"Check whether formulas can be satisfied in a given state."
function satisfy(formulas::Vector{<:Term}, state::State,
                 domain::Union{Domain,Nothing}=nothing; mode::Symbol=:any)
    # Do quick check as to whether formulas are in the set of facts
    if all(f -> f in state.facts, formulas) return true, Subst() end
    # Initialize Julog knowledge base
    if domain == nothing
        clauses = [Clause(f, Term[]) for f in state.facts]
    else
        clauses = Clause[collect(state.facts);
                         domain.axioms; type_clauses(domain.types)]
    end
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
    val = eval_term(formula, Julog.Subst(), state.fluents)
    # Return if formula evaluates to a Const (unwrapping if as_const=false)
    if isa(val, Const) return as_const ? val : val.name end
    # If val is not a Const, check if holds true in the state
    sat, _ = satisfy(Term[val], state, domain)
    return as_const ? Const(sat) : sat # Wrap in Const if as_const=true
end

"Create initial state from problem definition."
function initialize(problem::Problem)
    types = [@julog($ty(:o)) for (o, ty) in problem.objtypes]
    state = State(problem.init)
    union!(state.facts, types)
    return state
end

"Simulate a single state transition (action + triggered events) in a domain."
function transition(domain::Domain, state::State, action::Term)
    state = execute(action, state, domain)
    if length(domain.events) > 0
        state = trigger(domain.events, state, domain)
    end
    return state
end

function transition(domain::Domain, state::State, actions::Set{<:Term})
    state = execpar(actions, state, domain) # Execute in parallel
    if length(domain.events) > 0
        state = trigger(domain.events, state, domain)
    end
    return state
end

"Simulate state trajectory for a given domain and sequence of actions."
function simulate(domain::Domain, state::State, actions::Vector{<:Term};
                  callback::Function=(d,s,a)->nothing)
    trajectory = State[state]
    callback(domain, state, Const(:start))
    for act in actions
        state = transition(domain, state, act)
        push!(trajectory, state)
        callback(domain, state, act)
    end
    return trajectory
end

function simulate(domain::Domain, state::State, actions::Vector{Set{<:Term}};
                  callback::Function=(d,s,a)->nothing)
    trajectory = State[state]
    callback(domain, state, Set([Const(:start)]))
    for acts in actions
        state = transition(domain, state, acts)
        push!(trajectory, state)
        callback(domain, state, acts)
    end
    return trajectory
end
