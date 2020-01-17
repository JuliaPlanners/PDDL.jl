export get_diff, get_dist, update, check, execute, satisfy, init_state

"Check whether formulas can be satisfied in a given state."
function satisfy(formulas::Vector{<:Term}, state::State,
                 domain::Union{Domain,Nothing}=nothing; mode::Symbol=:any)
    # Initialize FOL knowledge base to the set of facts
    clauses = state.facts
    # If domain is provided, add domain axioms and type clauses
    if domain != nothing
        clauses = Clause[clauses; domain.axioms; type_clauses(domain.types)]
    end
    # Pass in fluents as a dictionary of functions
    funcs = state.fluents
    return resolve(formulas, clauses; funcs=funcs, mode=mode)
end

satisfy(formula::Term, state::State, domain::Union{Domain,Nothing}=nothing;
        options...) = satisfy(Term[formula], state, domain; options...)

"Create initial state from problem definition."
function init_state(problem::Problem)
    types = [@fol($ty(:o) <<= true) for (o, ty) in problem.objtypes]
    facts = Clause[]
    fluents = Dict{Symbol,Any}()
    for clause in problem.init
        if clause.head.name == :(==)
            # Initialize fluents
            term, val = clause.head.args[1], clause.head.args[2]
            @assert !isa(term, Var) "Initial terms cannot be unbound variables."
            @assert isa(val, Const) "Terms must be initialized to constants."
            if isa(term, Const)
                # Assign term to constant value
                fluents[term.name] = val.name
            else
                # Assign entry in look-up table
                lookup = get!(fluents, term.name, Dict())
                lookup[Tuple(a.name for a in term.args)] = val.name
            end
        else
            push!(facts, clause)
        end
    end
    return State([facts; types], fluents)
end

"Convert type hierarchy to list of FOL clauses."
function type_clauses(typetree::Dict{Symbol,Vector{Symbol}})
    clauses = [[Clause(@fol($ty(X)), Term[@fol($s(X))]) for s in subtys]
               for (ty, subtys) in typetree if length(subtys) > 0]
    return length(clauses) > 0 ? reduce(vcat, clauses) : Clause[]
end

"Representation of an effect as the tuple (additions, deletions)."
EffectDiff = Tuple{Vector{Term}, Vector{Term}}

"Entry in a categorical effect distribution."
EffectDistEntry = NamedTuple{(:prob, :add, :del),
                             Tuple{Float64, Vector{Term}, Vector{Term}}}

"A (categorical) distribution over possible effects."
EffectDist = Vector{EffectDistEntry}

"Return additions and deletions of an effect as a list of FOL terms."
function get_diff(effect::Term, state::Union{State,Nothing}=nothing,
                  domain::Union{Domain,Nothing}=nothing)
    add, del = Term[], Term[]
    if effect.name == :and
        for arg in effect.args
            diff = get_diff(arg, state, domain)
            append!(add, diff[1])
            append!(del, diff[2])
        end
    elseif effect.name == :when
        cond, eff = effect.args[1], effect.args[2]
        if state == nothing || satisfy([cond], state, domain)[1] == true
            # Return eff if cond is satisfied
            diff = get_diff(eff, state, domain)
            append!(add, diff[1])
            append!(del, diff[2])
        end
    elseif effect.name == :forall
        cond, eff = effect.args[1], effect.args[2]
        if state != nothing
            # Find objects matching cond and apply effects for each
            _, subst = satisfy([cond], state, domain; mode=:all)
            for s in subst
                diff = get_diff(substitute(eff, s), state, domain)
                append!(add, diff[1])
                append!(del, diff[2])
            end
        end
    elseif effect.name == :probabilistic
        n_effs = Int(length(effect.args)/2)
        r, cum_prob = rand(), 0.0
        for i in 1:n_effs
            # Sample a random effect
            prob, eff = effect.args[2*i-1].name, effect.args[2*i]
            if cum_prob <= r < (cum_prob + prob)
                diff = get_diff(eff, state, domain)
                append!(add, diff[1])
                append!(del, diff[2])
            end
            cum_prob += prob
        end
    elseif effect.name in [:not, :!]
        push!(del, effect.args[1])
    else
        push!(add, effect)
    end
    return (add, del)
end

"Return positive / negative effects of action as a list of FOL terms."
function get_effects(act::Action)
    return get_diff(act.effect)
end

function get_effects(act::Action, args::Vector{Term})
    subst = Subst(var => val for (var, val) in zip(act.args, args))
    effect = substitute(act.effect, subst)
    effect = is_ground(effect) ? eval_term(effect, Subst()) : effect
    return get_diff(effect)
end

"Return positive / negative effects of event as a list of FOL terms."
function get_effects(evt::Event)
    return get_diff(evt.effect)
end

"Helper function to take Cartesian product of two effect distributions"
function product(dist1::EffectDist, dist2::EffectDist)
    product_dist = EffectDist()
    for w1 in dist1 for w2 in dist2
        prod_w = (prob=w1.prob * w2.prob,
                  add=Term[w1.add; w2.add],
                  del=Term[w1.del; w2.del])
        push!(product_dist, prod_w)
    end end
    return product_dist
end

"Return distribution over possible effects, given a state."
function get_dist(effect::Term, state::State,
                  domain::Union{Domain,Nothing}=nothing)
    dist = [(prob=1.0, add=Term[], del=Term[])]
    if effect.name == :and
        sub_dists = [get_dist(arg, state, domain) for arg in effect.args]
        dist = foldl(product, sub_dists; init=dist)
    elseif effect.name == :when
        cond, eff = effect.args[1], effect.args[2]
        if satisfy([cond], state, domain)[1] == true
            dist = get_dist(eff, state, domain)
        end
    elseif effect.name == :forall
        cond, eff = effect.args[1], effect.args[2]
        # Find objects matching cond and apply effects for each
        _, subst = satisfy([cond], state, domain; mode=:all)
        sub_dists = [get_dist(substitute(eff, s), state, domain) for s in subst]
        dist = foldl(product, sub_dists; init=dist)
    elseif effect.name == :probabilistic
        n_effs = Int(length(effect.args)/2)
        dist = EffectDist()
        for i in 1:n_effs
            prob, eff = effect.args[2*i-1].name, effect.args[2*i]
            sub_dist = get_dist(eff, state, domain)
            for w in sub_dist
                push!(dist, (prob=prob*w.prob, add=w.add, del=w.del))
            end
        end
    elseif effect.name in [:not, :!]
        dist = [(prob=1.0, add=Term[], del=Term[effect.args[1]])]
    else
        dist = [(prob=1.0, add=Term[effect], del=Term[])]
    end
    return dist
end

"Return the effect of a null operation as either a difference or distribution."
function no_effect(as_dist::Bool=false)
    if as_dist
        return [(prob=1.0, add=Term[], del=Term[])]
    else
        return (Term[], Term[])
    end
end

"Combine list of state differences into single diff."
function combine_diffs(diffs::Vector, as_dist::Bool=false)
    if as_dist
        return foldl(product, diffs; init=no_effect(as_dist))
    else
        if length(diffs) == 0 return (Term[], Term[]) end
        add, del = first.(diffs), last.(diffs)
        add, del = reduce(vcat, add), reduce(vcat, del)
        return add, del
    end
end

"Update a world state with additions and deletions."
function update(state::State, diff::EffectDiff)
    additions, deletions = diff
    facts = filter(c -> !(c.head in deletions), state.facts)
    facts = unique!(Clause[facts; additions])
    fluents = state.fluents
    return State(facts, fluents)
end

"Update a state with a distribution over additions and deletions"
function update(state::State, dist::EffectDist)
    return [(e.prob, update(state, (e.add, e.del))) for e in dist]
end

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
    effect = eval_term(substitute(act.effect, subst), Subst())
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

"Execute a set of actions on a state."
function execute(actions::Vector{Term}, state::State, domain::Domain;
                 as_dist::Bool=false, as_diff::Bool=false)
    diffs = [execute(domain.actions[act.name], act.args, state, domain;
                     as_dist=as_dist, as_diff=true) for act in actions]
    filter!(d -> d != nothing, diffs)
    diff = combine_diffs(diffs, as_dist)
    # Return either the difference or the updated state
    return as_diff ? diff : update(state, diff)
end

"Execute an event if its preconditions hold on a world state."
function execute(evt::Event, state::State,
                 domain::Union{Domain,Nothing}=nothing;
                 as_dist::Bool=false, as_diff::Bool=false)
    # Check whether preconditions hold
    sat, subst = satisfy([evt.precond], state, domain; mode=:all)
    if !sat
        @debug "Precondition $(evt.precond) does not hold."
        return as_diff ? no_effect(as_dist) : state
    end
    # Update state with effects for each matching substitution
    effects = [eval_term(substitute(evt.effect, s), Subst()) for s in subst]
    if as_dist
        # Compute product distribution
        eff_dists = [get_dist(e, state) for e in effects]
        diff = combine_diffs(eff_dists, as_dist)
    else
        # Accumulate effect diffs
        diff = combine_diffs([get_diff(e, state) for e in effects])
    end
    # Return either the difference or the updated state
    return as_diff ? diff : update(state, diff)
end

"Execute a set of events on a world state."
function execute(events::Vector{Event}, state::State,
                 domain::Union{Domain,Nothing}=nothing;
                 as_dist::Bool=false, as_diff::Bool=false)
    diffs = [execute(e, state, domain; as_dist=as_dist, as_diff=true)
             for e in events]
    filter!(d -> d != nothing, diffs)
    diff = combine_diffs(diffs, as_dist)
    # Return either the difference or the updated state
    return as_diff ? diff : update(state, diff)
end
