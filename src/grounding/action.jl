"""
    GroundAction(name, term, preconds, effect)

Ground action definition, represented by the `name` of its corresponding action
schema, a `term` with grounded arguments, a list of `preconds`, and an `effect`,
represented as a [`PDDL.GenericDiff`](@ref) or [`PDDL.ConditionalDiff`](@ref).
"""
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
    args::Vector{Var}
    types::Vector{Symbol}
    actions::Dict{Compound,GroundAction}
end

function GroundActionGroup(name::Symbol, args, types,
                           actions::AbstractVector{GroundAction})
    actions = Dict(act.term => act for act in actions)
    return GroundActionGroup(name, args, types, actions)
end

get_name(action::GroundActionGroup) = action.name

get_argvars(action::GroundActionGroup) = action.args

get_argtypes(action::GroundActionGroup) = action.types

"Maximum limit for grounding by enumerating over typed objects."
const MAX_GROUND_BY_TYPE_LIMIT = 250

"Minimum number of static conditions for grounding by static satisfaction."
const MIN_GROUND_BY_STATIC_LIMIT = 1

"Returns an iterator over all ground arguments of an `action`."
function groundargs(domain::Domain, state::State, action::Action;
                    statics=nothing)
    if isempty(get_argtypes(action))
        return ((),)
    end
    # Extract static preconditions
    statics = (statics === nothing) ? infer_static_fluents(domain) : statics
    preconds = flatten_conjs(get_precond(action))
    filter!(p -> p.name in statics, preconds)
    # Decide whether to generate by satisfying static preconditions
    n_groundings = prod(get_object_count(domain, state, ty)
                        for ty in get_argtypes(action))
    use_preconds = n_groundings > MAX_GROUND_BY_TYPE_LIMIT &&
                   length(preconds) >= MIN_GROUND_BY_STATIC_LIMIT
    if use_preconds # Filter using preconditions
        # Add type conditions for correctness
        act_vars, act_types = get_argvars(action), get_argtypes(action)
        typeconds = (pddl"($ty $v)" for (v, ty) in zip(act_vars, act_types))
        conds = [preconds; typeconds...]
        # Find all arguments that satisfy static preconditions
        argvars = get_argvars(action)
        iter = ([subst[v] for v in argvars] for
                subst in satisfiers(domain, state, conds))
        return iter
    else # Iterate over domain of each type
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
    precond = to_nnf(dequantify(get_precond(action),
                                domain, state, statics))
    effects = flatten_conditions(dequantify(get_effect(action),
                                            domain, state, statics))
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
function groundactions(domain::Domain, state::State;
                       statics=infer_static_fluents(domain))
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
    precond=to_nnf(dequantify(get_precond(action),
                              domain, state, statics)),
    effects=flatten_conditions(dequantify(get_effect(action),
                                          domain, state, statics))
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
    # Decide whether to simplify precondition to CNF
    if is_dnf(precond) # Split disjunctive precondition into conditional effects
        conds = map(precond.args) do clause
            terms = flatten_conjs(clause)
            return [Term[terms; cs] for cs in conds]
        end
        conds = reduce(vcat, conds)
        diffs = repeat(diffs, length(precond.args))
        preconds = Term[]
    elseif is_cnf(precond) # Keep as CNF if possible
        preconds = precond.args
    else # Otherwise convert to CNF
        preconds = to_cnf_clauses(precond)
    end
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
function ground(domain::Domain, state::State, action::Action;
                statics=infer_static_fluents(domain))
    ground_acts = groundactions(domain, state, action; statics=statics)
    vars, types = get_argvars(action), get_argtypes(action)
    return GroundActionGroup(get_name(action), vars, types, ground_acts)
end
