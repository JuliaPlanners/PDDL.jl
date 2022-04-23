"Ground action definition."
struct GroundAction <: Action
    name::Symbol
    term::Compound
    preconds::Vector{Term}
    effect::Union{GenericDiff,ConditionalDiff}
end

get_name(action::GroundAction) = action.name

get_argvals(action::GroundAction) = term.args

get_precond(action::GroundAction) = Compound(:and, action.preconds)

get_effect(action::GroundAction) = as_term(action.effect)

Base.convert(::Type{Compound}, action::GroundAction) = action.term

Base.convert(::Type{Const}, action::GroundAction) =
    isempty(action.term.args) ? action.term : error("Action has arguments.")

"Group of ground actions with a shared schema."
struct GroundActionGroup <: Action
    name::Symbol
    actions::Dict{Compound,GroundAction}
end

function GroundActionGroup(name::Symbol, actions::AbstractVector{GroundAction})
    actions = Dict(act.term => act for act in actions)
    return GroundActionGroup(name, actions)
end

get_name(action::GroundActionGroup) = action.name

"Returns an iterator over all ground arguments of an `action`."
function groundargs(domain::Domain, state::State, action::Action;
                    statics=nothing)
    if isempty(get_argtypes(action))
        return ((),)
    elseif all(get_argtypes(action) .== :object)
        # Extract static preconditions
        statics = (statics === nothing) ? infer_static_fluents(domain) : statics
        preconds = flatten_conjs(get_precond(action))
        filter!(p -> p.name in statics, preconds)
        # Find all arguments that satisfy static preconditions
        argvars = get_argvars(action)
        iter = ([subst[v] for v in argvars] for
                subst in satisfiers(domain, state, preconds))
        return iter
    else
        iters = (get_objects(domain, state, ty) for ty in get_argtypes(action))
        return Iterators.product(iters...)
    end
end

"""
    groundactions(domain::Domain, state::State, action::Action)

Returns ground actions for a lifted `action` in a `domain` and initial `state`.
"""
function groundactions(domain::Domain, state::State, action::Action;
                       statics=infer_static_fluents(domain))
    ground_acts = GroundAction[]
    # Dequantify and flatten preconditions and effects
    precond = dequantify(get_precond(action), domain, state)
    effects = flatten_conditions(dequantify(get_effect(action), domain, state))
    # Iterate over possible groundings
    for args in groundargs(domain, state, action; statics=statics)
        # Construct ground action for each set of arguments
        act = ground(domain, state, action, args;
                     statics=statics, precond=precond, effects=effects)
        # Skip actions that are never satisfiable
        if (act === nothing) continue end
        push!(ground_acts, act)
    end
    return ground_acts
end

function groundactions(domain::Domain, state::State, action::GroundActionGroup,
                       statics=nothing)
    return values(action.actions)
end

"""
    groundactions(domain::Domain, state::State)

Returns all ground actions for a `domain` and initial `state`.
"""
function groundactions(domain::Domain, state::State)
    statics = infer_static_fluents(domain)
    iters = (groundactions(domain, state, act; statics=statics)
             for act in values(get_actions(domain)))
    return collect(Iterators.flatten(iters))
end

"""
    ground(domain::Domain, state::State, action::Action, args)

Return ground action given a lifted `action` and action `args`. If the action
is never satisfiable given the `domain` and `state`, return `nothing`.
"""
function ground(domain::Domain, state::State, action::Action, args;
    statics=infer_static_fluents(domain),
    precond=dequantify(get_precond(action), domain, state; statics=statics),
    effects=flatten_conditions(dequantify(get_effect(action), domain, state))
)
    act_name = get_name(action)
    act_vars = get_argvars(action)
    term = Compound(act_name, collect(args))
    # Substitute and simplify precondition
    subst = Subst(var => val for (var, val) in zip(act_vars, args))
    precond = substitute(precond, subst)
    precond = simplify_statics(precond, domain, state, statics)
     # Return nothing if unsatisfiable
    if (precond.name == false) return nothing end
    preconds = to_cnf_clauses(precond)
    # Unpack effects into conditions and effects
    conds, effects = effects
    # Simplify conditions of conditional effects
    conds = map(conds) do cs
        isempty(cs) && return cs
        cond = substitute(Compound(:and, cs), subst)
        cond = simplify_statics(cond, domain, state, statics)
        return to_cnf_clauses(cond)
    end
    # Construct diffs from conditional effect terms
    diffs = map(effects) do es
        eff = substitute(Compound(:and, es), subst)
        return effect_diff(domain, state, eff)
    end
    # Delete unsatisfiable branches
    unsat_idxs = findall(cs -> Const(false) in cs, conds)
    deleteat!(conds, unsat_idxs)
    deleteat!(diffs, unsat_idxs)
    # Construct conditional diff if necessary
    if length(diffs) > 1
        effect = ConditionalDiff(conds, diffs)
    elseif length(diffs) == 1
        effect = diffs[1]
        preconds = append!(preconds, conds[1])
        filter!(c -> c != Const(true), preconds)
    else # Return nothing if no satisfiable branches
        return nothing
    end
    # Return ground action
    return GroundAction(act_name, term, preconds, effect)
end

"""
    ground(domain::Domain, state::State, action::Action)

Grounds a lifted `action` in a `domain` and initial `state`, returning a
group of grounded actions.
"""
function ground(domain::Domain, state::State, action::GenericAction;
                statics=infer_static_fluents(domain))
    ground_acts = groundactions(domain, state, action; statics=statics)
    return GroundActionGroup(action.name, ground_acts)
end
