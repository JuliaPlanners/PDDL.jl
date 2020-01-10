export get_diff, get_dist, update, check, execute

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
function get_diff(effect::Term, model=nothing)
    add, del = Term[], Term[]
    if effect.name == :and
        for arg in effect.args
            diff = get_diff(arg, model)
            append!(add, diff[1])
            append!(del, diff[2])
        end
    elseif effect.name == :when
        cond, eff = effect.args[1], effect.args[2]
        if model == nothing || resolve(cond, model; mode=:any)[1] == true
            # Return eff if cond is satisfied
            diff = get_diff(eff, model)
            append!(add, diff[1])
            append!(del, diff[2])
        end
    elseif effect.name == :forall
        cond, eff = effect.args[1], effect.args[2]
        if model != nothing
            # Find objects matching cond and apply effects for each
            _, subst = resolve(cond, model)
            for s in subst
                diff = get_diff(substitute(eff, s), model)
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
                diff = get_diff(eff, model)
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

"Return distribution over possible effects, given a model."
function get_dist(effect::Term, model::Vector{Clause})
    dist = [(prob=1.0, add=Term[], del=Term[])]
    if effect.name == :and
        sub_dists = [get_dist(arg, model) for arg in effect.args]
        dist = foldl(product, sub_dists; init=dist)
    elseif effect.name == :when
        cond, eff = effect.args[1], effect.args[2]
        if resolve([cond], model; mode="any")[1] == true
            dist = get_dist(eff, model)
        end
    elseif effect.name == :probabilistic
        n_effs = Int(length(effect.args)/2)
        dist = EffectDist()
        for i in 1:n_effs
            prob, eff = effect.args[2*i-1].name, effect.args[2*i]
            sub_dist = get_dist(eff, model)
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

"Combine list of model differences into single diff."
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

"Update a world model with additions and deletions."
function update(model::Vector{Clause}, diff::EffectDiff)
    additions, deletions = diff
    model = filter(c->(length(c.body) > 0 || !(c.head in deletions)), model)
    model = unique!(Clause[model; additions])
    return model
end

"Update a model with a distribution over additions and deletions"
function update(model::Vector{Clause}, dist::EffectDist)
    return [(e.prob, update(model, (e.add, e.del))) for e in dist]
end

"Check whether an action can be executed on a model."
function check(act::Action, args::Vector{<:Term}, model::Vector{Clause},
               axioms::Vector{Clause}=Clause[])
   if any([!is_ground(a) for a in args])
       error("Not all arguments are ground.")
   end
   arg_subst = Subst(var => val for (var, val) in zip(act.args, args))
   ref_subst = Subst()
   # Resolve deictic references
   for (var, term) in act.refs
       term = substitute(term, arg_subst)
       sat, var_subst = resolve([term], [model; axioms]; mode=:any)
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
   sat, _ = resolve([precond; typecond], [model; axioms]; mode=:any)
   return sat, subst
end

"Execute an action with supplied args on a world model."
function execute(act::Action, args::Vector{<:Term}, model::Vector{Clause},
                 axioms::Vector{Clause}=Clause[];
                 as_dist::Bool=false, as_diff::Bool=false)
    # Check whether references resolve and preconditions hold
    sat, subst = check(act, args, model, axioms)
    if !sat
        @debug "Precondition $precond does not hold."
        return nothing
    end
    # Substitute arguments and preconditions
    effect = substitute(act.effect, subst)
    # TODO : make term evaluation work with foralls
    # effect = eval_term(substitute(act.effect, subst), Subst())
    # if effect == nothing
    #     error("Effect is not ground after substitution.")
    # end
    # Compute effects in the appropriate form
    if as_dist
        # Compute categorical distribution over differences
        diff = get_dist(effect, [model; axioms])
    else
        # Sample a possible difference
        diff = get_diff(effect, [model; axioms])
    end
    # Return either the difference or the updated model
    return as_diff ? diff : update(model, diff)
end

"Execute a set of actions on model."
function execute(actions::Vector{Term}, act_defs::Dict{Symbol,Action},
                 model::Vector{Clause}, axioms::Vector{Clause}=Clause[];
                 as_dist::Bool=false, as_diff::Bool=false)
    diffs = [execute(act_defs[act.name], act.args, model, axioms;
                     as_dist=as_dist, as_diff=true)
             for act in actions]
    filter!(d -> d != nothing, diffs)
    diff = combine_diffs(diffs, as_dist)
    # Return either the difference or the updated model
    return as_diff ? diff : update(model, diff)
end

"Execute an event if its preconditions hold on a world model."
function execute(evt::Event, model::Vector{Clause}, axioms::Vector{Clause}=[];
                 as_dist::Bool=false, as_diff::Bool=false)
    # Check whether preconditions hold
    clauses = [model; axioms]
    sat, subst = resolve([evt.precond], clauses)
    if !sat
        @debug "Precondition $(evt.precond) does not hold."
        return as_diff ? no_effect(as_dist) : model
    end
    # Update model with effects for each matching substitution
    effects = [eval_term(substitute(evt.effect, s), Subst()) for s in subst]
    if as_dist
        # Compute product distribution
        eff_dists = [get_dist(e, clauses) for e in effects]
        diff = combine_diffs(eff_dists, as_dist)
    else
        # Accumulate effect diffs
        diff = combine_diffs([get_diff(e, clauses) for e in effects])
    end
    # Return either the difference or the updated model
    return as_diff ? diff : update(model, diff)
end

"Execute a set of events on a world model."
function execute(events::Vector{Event}, model::Vector{Clause},
                 axioms::Vector{Clause}=[];
                 as_dist::Bool=false, as_diff::Bool=false)
    diffs = [execute(e, model, axioms; as_dist=as_dist, as_diff=true)
             for e in events]
    filter!(d -> d != nothing, diffs)
    diff = combine_diffs(diffs, as_dist)
    # Return either the difference or the updated model
    return as_diff ? diff : update(model, diff)
end
