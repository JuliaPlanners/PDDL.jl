# Functions for handling and executing actions on a state

const no_op = Action(Compound(Symbol("--"), []), @julog(true), @julog(and()))

"Get preconditions of an action as a list."
function get_preconditions(act::Action, args::Vector{<:Term};
                           converter::Function=flatten_conjs)
    subst = Subst(var => val for (var, val) in zip(act.args, args))
    precond = substitute(act.precond, subst)
    return converter(precond)
end

get_preconditions(act::Action; converter::Function=flatten_conjs) =
    converter(act.precond)

get_preconditions(act::Term, domain::Domain; kwargs...) =
    get_preconditions(domain.actions[act.name], get_args(act); kwargs...)

"Get effect term of an action with variables substituted by arguments."
function get_effect(act::Action, args::Vector{<:Term})
    subst = Subst(var => val for (var, val) in zip(act.args, args))
    return substitute(act.effect, subst)
end

get_effect(act::Term, domain::Domain) =
    get_effect(domain.actions[act.name], get_args(act))

"Check whether an action is available (can be executed) in a state."
function available(act::Action, args::Vector{<:Term}, state::State,
                   domain::Union{Domain,Nothing}=nothing)
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
    sat, _ = satisfy(conds, state, domain)
    return sat
end

available(act::Term, state::State, domain::Domain) =
    available(domain.actions[act.name], act.args, state, domain)

"Cache of available actions for a given domain and state."
const available_action_cache = Dict{UInt,Dict{UInt,Vector{Term}}}()

"Clear cache of available actions."
clear_available_action_cache!() = empty!(available_action_cache)
clear_available_action_cache!(domain::Domain) =
    empty!(available_action_cache[objectid(domain)])

"Return list of available actions in a state, given a domain."
function available(state::State, domain::Domain; use_cache::Bool=true)
    if use_cache # Look up actions in cache
        cache = get!(available_action_cache, objectid(domain),
                     Dict{UInt,Vector{Term}}())
        state_hash = hash(state)
        if haskey(cache, state_hash) return copy(cache[state_hash]) end
    end
    # Ground all action definitions with arguments
    actions = Term[]
    for act in values(domain.actions)
        typecond = [@julog($ty(:v)) for (v, ty) in zip(act.args, act.types)]
        # Prepend type conditions when necessary for correctness
        conds = has_fluent(act.precond, domain) || has_quantifier(act.precond) ?
            [typecond; flatten_conjs(act.precond)] :
            [flatten_conjs(act.precond); typecond]
        # Find all substitutions that satisfy preconditions
        sat, subst = satisfy(conds, state, domain; mode=:all)
        if !sat continue end
        for s in subst
            args = [s[v] for v in act.args if v in keys(s)]
            if any([!is_ground(a) for a in args]) continue end
            term = isempty(args) ? Const(act.name) : Compound(act.name, args)
            push!(actions, term)
        end
    end
    if use_cache cache[state_hash] = copy(actions) end
    return actions
end

"Check whether an action is relevant (can lead) to a state."
function relevant(act::Action, args::Vector{<:Term}, state::State,
                  domain::Union{Domain,Nothing}=nothing; strict::Bool=false)
   if any(!is_ground(a) for a in args)
       error("Not all arguments are ground.")
   end
   subst = Subst(var => val for (var, val) in zip(act.args, args))
   # Compute postconditions from the action's effect
   diff = get_diff(substitute(act.effect, subst))
   postcond = Term[strict ? diff.add : Compound(:or, diff.add);
                   [@julog(not(:t)) for t in diff.del]]
   # Construct type conditions of the form "type(val)"
   typecond = (all(ty == :object for ty in act.types) ? Term[] :
               [@julog($ty(:v)) for (v, ty) in zip(args, act.types)])
   # Check whether postconditions hold
   sat, _ = satisfy([postcond; typecond], state, domain)
   return sat
end

relevant(act::Term, state::State, domain::Domain; kwargs...) =
    relevant(domain.actions[act.name], act.args, state, domain; kwargs...)

"Cache of relevant actions for a given domain and state."
const relevant_action_cache = Dict{Symbol,Dict{UInt,Vector{Term}}}()

"Clear cache of relevant actions."
clear_relevant_action_cache!() = empty!(relevant_action_cache)
clear_relevant_action_cache!(domain::Domain) =
    empty!(relevant_action_cache[objectid(domain)])

"Return list of actions relevant to achieving a state, given a domain."
function relevant(state::State, domain::Domain;
                  strict::Bool=false, use_cache::Bool=true)
    if use_cache # Look up actions in cache
        cache = get!(relevant_action_cache, hash(strict, objectid(domain)),
                     Dict{UInt,Vector{Term}}())
        state_hash = hash(state)
        if haskey(cache, state_hash) return copy(cache[state_hash]) end
    end
    actions = Term[]
    for act in values(domain.actions)
        # Compute postconditions from the action's effect
        diff = get_diff(act.effect)
        postcond = Term[strict ? diff.add : Compound(:or, diff.add);
                        [@julog(not(:t)) for t in diff.del]]
        typecond = [@julog($ty(:v)) for (v, ty) in zip(act.args, act.types)]
        conds = postcond
        # Include type conditions when necessary for correctness
        if domain.requirements[:typing]
            append!(conds, typecond)
        elseif domain.requirements[Symbol("conditional-effects")]
            prepend!(conds, typecond)
        end
        # Find all substitutions that satisfy the postconditions
        sat, subst = satisfy(conds, state, domain; mode=:all)
        if !sat continue end
        for s in subst
            args = [s[v] for v in act.args if v in keys(s)]
            if any([!is_ground(a) for a in args]) continue end
            term = isempty(args) ? Const(act.name) : Compound(act.name, args)
            push!(actions, term)
        end
    end
    if use_cache cache[state_hash] = copy(actions) end
    return actions
end

"Execute an action with supplied args on a world state."
function execute(act::Action, args::Vector{<:Term}, state::State,
                 domain::Union{Domain,Nothing}=nothing;
                 as_dist::Bool=false, as_diff::Bool=false,
                 check::Bool=true, fail_mode::Symbol=:error)
    # Check whether references resolve and preconditions hold
    if check && !available(act, args, state, domain)
        if fail_mode == :no_op return as_diff ? no_effect(as_dist) : state end
        error("Precondition $(act.precond) does not hold.") # Error by default
    end
    # Substitute arguments and preconditions
    # TODO : Check for non-ground terms outside of quantified formulas
    subst = Subst(var => val for (var, val) in zip(act.args, args))
    effect = substitute(act.effect, subst)
    # Compute effects in the appropriate form
    if as_dist
        # Compute categorical distribution over differences
        diff = get_dist(effect, state, domain)
    else
        # Sample a possible difference
        diff = get_diff(effect, state, domain)
    end
    # Return either the difference or the updated state
    return as_diff ? diff : update(state, diff)
end

function execute(act::Term, state::State, domain::Domain; options...)
    if act.name in keys(domain.actions)
        act_def, act_args = domain.actions[act.name], get_args(act)
        execute(act_def, act_args, state, domain; options...)
    elseif act.name == Symbol("--")
        execute(no_op, Term[], state, domain; options...)
    else
        error("Unknown action: $act")
    end
end

"Execute a list of actions in sequence on a state."
function execute(actions::Vector{<:Term}, state::State, domain::Domain;
                 as_dist::Bool=false, as_diff::Bool=false, options...)
    state = copy(state)
    for act in actions
        diff = execute(domain.actions[act.name], get_args(act), state, domain;
                       as_dist=as_dist, as_diff=true, options...)
        update!(state, diff)
    end
    # Return either the difference or the final state
    return as_diff ? diff : state
end

"Execute a list of actions in sequence on a state."
execseq(actions::Vector{<:Term}, state::State, domain::Domain; options...) =
    execute(actions, state, domain; options...)

"Execute a set of actions in parallel on a state."
function execute(actions::Set{<:Term}, state::State, domain::Domain;
                 as_dist::Bool=false, as_diff::Bool=false, options...)
    diffs = [execute(domain.actions[act.name], get_args(act), state, domain;
                     as_dist=as_dist, as_diff=true, options...)
             for act in actions]
    diff = combine(diffs...)
    # Return either the difference or the updated state
    return as_diff ? diff : update(state, diff)
end

"Execute a set of actions in parallel on a state."
execpar(actions::Set{<:Term}, state::State, domain::Domain; options...) =
    execute(actions, state, domain; options...)
execpar(actions::Vector{<:Term}, state::State, domain::Domain; options...) =
    execute(Set(actions), state, domain; options...)
