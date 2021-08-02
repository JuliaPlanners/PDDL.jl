# Functions for handling and executing actions on a state

const no_op = GenericAction(Compound(Symbol("--"), []), @julog(true), @julog(and()))

"Get preconditions of an action as a list."
function get_preconditions(act::GenericAction, args::Vector{<:Term};
                           converter::Function=flatten_conjs)
    subst = Subst(var => val for (var, val) in zip(act.args, args))
    precond = substitute(act.precond, subst)
    return converter(precond)
end

get_preconditions(act::GenericAction; converter::Function=flatten_conjs) =
    converter(act.precond)

get_preconditions(act::Term, domain::GenericDomain; kwargs...) =
    get_preconditions(domain.actions[act.name], get_args(act); kwargs...)

"Get effect term of an action with variables substituted by arguments."
function get_effect(act::GenericAction, args::Vector{<:Term})
    subst = Subst(var => val for (var, val) in zip(act.args, args))
    return substitute(act.effect, subst)
end

get_effect(act::Term, domain::GenericDomain) =
    get_effect(domain.actions[act.name], get_args(act))

"Global flag for whether to cache available actions."
const _use_available_cache = Ref(true)
"Cache of available actions for a given domain and state."
const _available_action_cache = Dict{UInt,Dict{UInt,Vector{Term}}}()

"Globally enable or disable available action cache."
use_available_action_cache!(val::Bool=true) = _use_available_cache[] = val

"Clear cache of available actions."
clear_available_action_cache!() =
    (map(empty!, values(_available_action_cache));
     empty!(_available_action_cache))
clear_available_action_cache!(domain::GenericDomain) =
    empty!(_available_action_cache[objectid(domain)])

function available(domain::GenericDomain, state::GenericState;
                   use_cache::Bool=_use_available_cache[])
    if use_cache # Look up actions in cache
        cache = get!(_available_action_cache, objectid(domain),
                     Dict{UInt,Vector{Term}}())
        state_hash = hash(state)
        if haskey(cache, state_hash) return copy(cache[state_hash]) end
    end
    # Ground all action definitions with arguments
    actions = Term[]
    for act in values(domain.actions)
        typecond = (@julog($ty(:v)) for (v, ty) in zip(act.args, act.types))
        # Include type conditions when necessary for correctness
        p = act.precond
        if has_fluent(p, domain) || has_axiom(p, domain) || has_quantifier(p)
            conds = prepend!(flatten_conjs(p), typecond)
        elseif domain.requirements[:typing]
            conds = append!(flatten_conjs(p), typecond)
        else
            conds = flatten_conjs(p)
        end
        # Find all substitutions that satisfy preconditions
        subst = satisfiers(domain, state, conds)
        if length(subst) == 0 continue end
        for s in subst
            args = [s[v] for v in act.args if v in keys(s)]
            if any(!is_ground(a) for a in args) continue end
            term = isempty(args) ? Const(act.name) : Compound(act.name, args)
            push!(actions, term)
        end
    end
    if use_cache cache[state_hash] = copy(actions) end
    return actions
end

function available(domain::GenericDomain, state::GenericState,
                   act::GenericAction, args)
    if any(!is_ground(a) for a in args)
       error("Not all arguments are ground.")
    end
    subst = Subst(var => val for (var, val) in zip(act.args, args))
    # Construct type conditions of the form "type(val)"
    typecond = (all(ty == :object for ty in act.types) ? Term[] :
               [@julog($ty(:v)) for (v, ty) in zip(args, act.types)])
    # Check whether preconditions hold
    precond = substitute(act.precond, subst)
    conds = has_fluent(precond, state) || has_quantifier(precond) ?
        [typecond; precond] : [precond; typecond]
    return satisfy(domain, state, conds)
end

available(domain::GenericDomain, state::GenericState, act::Term) =
    available(domain, state, domain.actions[act.name], act.args)

"Global flag for whether to cache relevant actions."
const _use_relevant_cache = Ref(true)
"Cache of relevant actions for a given domain and state."
const _relevant_action_cache = Dict{UInt,Dict{UInt,Vector{Term}}}()

"Globally enable or disable available action cache."
use_relevant_action_cache!(val::Bool=true) = _use_relevant_cache[] = val

"Clear cache of relevant actions."
clear_relevant_action_cache!() =
    (map(empty!, values(_relevant_action_cache));
     empty!(_relevant_action_cache))
clear_relevant_action_cache!(domain::GenericDomain) =
    empty!(_relevant_action_cache[objectid(domain)])

function relevant(domain::GenericDomain, state::GenericState;
                  strict::Bool=false, use_cache::Bool=_use_relevant_cache[])
    if use_cache # Look up actions in cache
        cache = get!(_relevant_action_cache, hash(strict, objectid(domain)),
                     Dict{UInt,Vector{Term}}())
        state_hash = hash(state)
        if haskey(cache, state_hash) return copy(cache[state_hash]) end
    end
    actions = Term[]
    for act in values(domain.actions)
        # Compute postconditions from the action's effect
        diff = effect_diff(domain, state, act.effect)
        addcond = strict ? diff.add : [Compound(:or, diff.add)]
        delcond = [@julog(not(:t)) for t in diff.del]
        typecond = [@julog($ty(:v)) for (v, ty) in zip(act.args, act.types)]
        # Include type conditions when necessary for correctness
        if any(has_fluent(c, domain) ||
               has_quantifier(c) for c in [addcond; delcond])
            conds = [typecond; addcond; delcond]
        else
            conds = [addcond; typecond; delcond]
        end
        # Find all substitutions that satisfy the postconditions
        subst = satisfiers(domain, state, conds)
        if length(subst) == 0 continue end
        for s in subst
            args = [get(s, var, var) for var in act.args]
            if any(!is_ground(a) for a in args) continue end
            term = isempty(args) ? Const(act.name) : Compound(act.name, args)
            push!(actions, term)
        end
    end
    if use_cache cache[state_hash] = copy(actions) end
    return actions
end

function relevant(domain::GenericDomain, state::GenericState,
                  act::GenericAction, args; strict::Bool=false)
   if any(!is_ground(a) for a in args)
       error("Not all arguments are ground.")
   end
   subst = Subst(var => val for (var, val) in zip(act.args, args))
   # Compute postconditions from the action's effect
   diff = effect_diff(domain, state, substitute(act.effect, subst))
   postcond = Term[strict ? diff.add : Compound(:or, diff.add);
                   [@julog(not(:t)) for t in diff.del]]
   # Construct type conditions of the form "type(val)"
   typecond = (all(ty == :object for ty in act.types) ? Term[] :
               [@julog($ty(:v)) for (v, ty) in zip(args, act.types)])
   # Check whether postconditions hold
   return satisfy(domain, state, [postcond; typecond])
end

relevant(domain::GenericDomain, state::GenericState, act::Term; kwargs...) =
    relevant(domain, state, domain.actions[act.name], act.args; kwargs...)

function execute(domain::GenericDomain, state::GenericState,
                 act::GenericAction, args; as_diff::Bool=false,
                 check::Bool=true, fail_mode::Symbol=:error)
    # Check whether references resolve and preconditions hold
    if check && !available(domain, state, act, args)
        if fail_mode == :no_op return as_diff ? no_effect() : state end
        error("Precondition $(act.precond) does not hold.") # Error by default
    end
    # Substitute arguments and preconditions
    # TODO : Check for non-ground terms outside of quantified formulae
    subst = Subst(var => val for (var, val) in zip(act.args, args))
    effect = substitute(act.effect, subst)
    # Compute effect as a state diffference
    diff = effect_diff(domain, state, effect)
    # Return either the difference or the updated state
    return as_diff ? diff : update(state, diff)
end

function execute(domain::GenericDomain, state::GenericState, act::Term; options...)
    if act.name in keys(domain.actions)
        act_def, act_args = domain.actions[act.name], get_args(act)
        execute(domain, state, act_def, act_args; options...)
    elseif act.name == Symbol("--")
        execute(domain, state, no_op, Term[]; options...)
    else
        error("Unknown action: $act")
    end
end

function execute(domain::GenericDomain, state::GenericState,
                 actions::AbstractVector{<:Term};
                 as_diff::Bool=false, options...)
    state = copy(state)
    for act in actions
        diff = execute(domain, state, domain.actions[act.name], act.args;
                       as_diff=true, options...)
        if !as_diff update!(state, diff) end
    end
    # Return either the difference or the final state
    return as_diff ? diff : state
end

function regress(domain::GenericDomain, state::GenericState,
                 act::GenericAction, args; as_diff::Bool=false,
                 check::Bool=true, fail_mode::Symbol=:error)
    # Check whether action is relevant
    if check && !relevant(domain, state, act, args)
        if fail_mode == :no_op return as_diff ? Diff() : state end
        error("Effect $(act.effect) is not relevant.") # Error by default
    end
    subst = Subst(var => val for (var, val) in zip(act.args, args))
    precond = substitute(act.precond, subst)
    effect = substitute(act.effect, subst)
    # Compute regression difference as Precond - Additions
    # TODO: Handle conditional effects, disjunctive preconditions, etc.
    pre_diff = precond_diff(domain, state, precond)
    eff_diff = effect_diff(domain, state, effect)
    append!(pre_diff.del, eff_diff.add)
    return as_diff ? pre_diff : update(state, pre_diff)
end

function regress(domain::GenericDomain, state::GenericState, act::Term; options...)
    if act.name in keys(domain.actions)
        act_def, act_args = domain.actions[act.name], get_args(act)
        regress(domain, state, act_def, act_args; options...)
    elseif act.name == Symbol("--")
        regress(domain, state, no_op, Term[]; options...)
    else
        error("Unknown action: $act")
    end
end
