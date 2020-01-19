# Functions for handling effect formulas

"Representation of an effect as the tuple (additions, deletions)."
EffectDiff = Tuple{Vector{Term}, Vector{Term}}

"Entry in a categorical effect distribution."
EffectDistEntry = NamedTuple{(:prob, :add, :del),
                             Tuple{Float64, Vector{Term}, Vector{Term}}}

"A (categorical) distribution over possible effects."
EffectDist = Vector{EffectDistEntry}

"Return additions and deletions of an effect formula as a list of FOL terms."
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
