# Functions for handling and executing actions on a state

"Check whether an action can be executed on a state."
function check(act::Action, args::Vector{<:Term}, state::State,
               domain::Union{Domain,Nothing}=nothing)
   if any([!is_ground(a) for a in args])
       error("Not all arguments are ground.")
   end
   arg_subst = Subst(var => val for (var, val) in zip(act.args, args))
   ref_subst = Subst()
   # Resolve deictic references
   for (var, term) in act.refs
       term = substitute(term, arg_subst)
       sat, var_subst = satisfy([term], state, domain)
       if !sat
           error("Unresolvable deictic reference: $var : $term.")
       end
       ref_subst[var] = var_subst[1][var]
   end
   subst = merge(arg_subst, ref_subst)
   # Construct type conditions of the form "type(val)"
   typecond = (all(ty == :object for ty in act.types) ? Term[] :
               [@fol($ty(:v)) for (v, ty) in zip(args, act.types)])
   # Check whether preconditions hold
   precond = substitute(act.precond, subst)
   sat, _ = satisfy([precond; typecond], state, domain)
   return sat, subst
end

check(act::Term, state::State, domain::Domain; options...) =
    check(domain.actions[act.name], act.args, state, domain; options...)

"Execute an action with supplied args on a world state."
function execute(act::Action, args::Vector{<:Term}, state::State,
                 domain::Union{Domain,Nothing}=nothing;
                 as_dist::Bool=false, as_diff::Bool=false)
    # Check whether references resolve and preconditions hold
    sat, subst = check(act, args, state, domain)
    if !sat
        @debug "Precondition $precond does not hold."
        return nothing
    end
    # Substitute arguments and preconditions
    # TODO : Check for non-ground terms outside of quantified formulas
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

execute(act::Term, state::State, domain::Domain; options...) =
    execute(domain.actions[act.name], act.args, state, domain; options...)

"Execute a list of actions in sequence on a state."
function execute(actions::Vector{<:Term}, state::State, domain::Domain;
                 as_dist::Bool=false, as_diff::Bool=false)
    state = copy(state)
    for act in actions
        diff = execute(domain.actions[act.name], act.args, state, domain;
                       as_dist=as_dist, as_diff=true)
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
                 as_dist::Bool=false, as_diff::Bool=false)
    diffs = [execute(domain.actions[act.name], act.args, state, domain;
                     as_dist=as_dist, as_diff=true) for act in actions]
    filter!(d -> d != nothing, diffs)
    diff = combine(diffs...)
    # Return either the difference or the updated state
    return as_diff ? diff : update(state, diff)
end

"Execute a set of actions in parallel on a state."
execpar(actions::Set{<:Term}, state::State, domain::Domain; options...) =
    execute(actions, state, domain; options...)
execpar(actions::Vector{<:Term}, state::State, domain::Domain; options...) =
    execute(Set(actions), state, domain; options...)
