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

"""
    available(act::Action, args, state, domain=nothing)
    available(act::Term, state, domain)

Check whether `act` can be executed in the given `state` and `domain`.
"""
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
clear_available_action_cache!() =
    (map(empty!, values(available_action_cache)); empty!(available_action_cache))
clear_available_action_cache!(domain::Domain) =
    empty!(available_action_cache[objectid(domain)])

"""
    available(state, domain; use_cache=true)

Return the list of available actions in a given `state` and `domain`.
If `use_cache` is true, memoize the results in a global cache.
"""
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
        # Include type conditions when necessary for correctness
        if has_fluent(act.precond, domain) || has_quantifier(act.precond)
            conds = [typecond; flatten_conjs(act.precond)]
        elseif domain.requirements[:typing]
            conds = [flatten_conjs(act.precond); typecond]
        else
            conds = flatten_conjs(act.precond)
        end
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

"""
    relevant(act::Action, args, state, domain=nothing; strict=false)
    relevant(act::Term, state, domain; strict=false)

Check whether `act` is relevant (can lead to) a `state` in the given `domain`.
If `strict` is true, check that all added facts are true in `state`.
"""
function relevant(act::Action, args::Vector{<:Term}, state::State,
                  domain::Union{Domain,Nothing}=nothing; strict::Bool=false)
   if any(!is_ground(a) for a in args)
       error("Not all arguments are ground.")
   end
   subst = Subst(var => val for (var, val) in zip(act.args, args))
   # Compute postconditions from the action's effect
   diff = effect_diff(substitute(act.effect, subst))
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
const relevant_action_cache = Dict{UInt,Dict{UInt,Vector{Term}}}()

"Clear cache of relevant actions."
clear_relevant_action_cache!() =
    (map(empty!, values(relevant_action_cache)); empty!(relevant_action_cache))
clear_relevant_action_cache!(domain::Domain) =
    empty!(relevant_action_cache[objectid(domain)])

"""
    relevant(state, domain; strict=false, use_cache=true)

Return the list of actions relevant to achieving a `state` in a given `domain`.
If `strict` is true, check that all added facts are true in `state`.
If `use_cache` is true, memoize the results in a global cache.
"""
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
        diff = effect_diff(act.effect)
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
        if act.name == :drop println(conds) end
        # Find all substitutions that satisfy the postconditions
        sat, subst = satisfy(conds, state, domain; mode=:all)
        if !sat continue end
        for s in subst
            args = [get(s, var, var) for var in act.args]
            if any([!is_ground(a) for a in args]) continue end
            term = isempty(args) ? Const(act.name) : Compound(act.name, args)
            push!(actions, term)
        end
    end
    if use_cache cache[state_hash] = copy(actions) end
    return actions
end

"""
    execute(act::Action, args, state, domain=nothing; kwargs...)
    execute(act::Term, state, domain; kwargs...)

Execute the action `act` on the given `state`. If `act` is an `Action`
definition, `args` must be supplied for the action's parameters. If `act` is
a `Term`, parameters will be extracted from its arguments, but `domain` must
be supplied.

Returns the resulting state by default, but this can modified by keyword
arguments `as_dist=true` (returns a distribution), `as_diff=true` (returns a
`Diff` between states), or both (returns a distribution over `Diff`s).
By default, also `check`s that action preconditions hold, failing with
an error if `fail_mode=:error`, or treating the action as a `no_op` if
`fail_mode=:no_op`.
"""
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
    # TODO : Check for non-ground terms outside of quantified formulae
    subst = Subst(var => val for (var, val) in zip(act.args, args))
    effect = substitute(act.effect, subst)
    # Compute effects in the appropriate form
    if as_dist
        # Compute categorical distribution over differences
        diff = effect_dist(effect, state, domain)
    else
        # Sample a possible difference
        diff = effect_diff(effect, state, domain)
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

"""
    regress(act::Action, args, state, domain=nothing; kwargs...)
    regress(act::Term, state, domain; kwargs...)

Return the predecessor(s) that would lead to `state` upon executing `act`.
If `act` is an `Action` definition, `args` must be supplied for the action's
parameters. If `act` is a `Term`, parameters will be extracted from its
arguments, but `domain` must be supplied.
"""
function regress(act::Action, args::Vector{<:Term}, state::State,
                 domain::Union{Domain,Nothing}=nothing; as_diff::Bool=false,
                 check::Bool=true, fail_mode::Symbol=:error)
    # Check whether action is relevant
    if check && !relevant(act, args, state, domain)
        if fail_mode == :no_op return as_diff ? Diff() : state end
        error("Effect $(act.effect) is not relevant.") # Error by default
    end
    subst = Subst(var => val for (var, val) in zip(act.args, args))
    precond = substitute(act.precond, subst)
    effect = substitute(act.effect, subst)
    # Compute regression difference as Precond - Additions
    # TODO: Handle conditional effects, disjunctive preconditions, etc.
    pre_diff = precond_diff(precond, state)
    eff_diff = effect_diff(effect, state)
    append!(pre_diff.del, eff_diff.add)
    return as_diff ? pre_diff : update(state, pre_diff)
end

function regress(act::Term, state::State, domain::Domain; options...)
    if act.name in keys(domain.actions)
        act_def, act_args = domain.actions[act.name], get_args(act)
        regress(act_def, act_args, state, domain; options...)
    elseif act.name == Symbol("--")
        regress(no_op, Term[], state, domain; options...)
    else
        error("Unknown action: $act")
    end
end
