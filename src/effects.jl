# Functions for handling effect formulae

"Representation of an effect as additions, deletions, and assignments."
mutable struct Diff
    add::Vector{Term} # List of additions
    del::Vector{Term} # List of deletions
    ops::Dict{Term,Any} # Dictionary of assignment operations
end

Diff() = Diff(Term[], Term[], Dict{Term,Any}())

"Returns true if the diff contains a matching term."
function contains_term(diff::Diff, term::Term)
    return (any(has_subterm(d, term) for d in diff.add) ||
            any(has_subterm(d, term) for d in diff.del) ||
            any(has_subterm(d, term) for d in keys(diff.ops)))
end

"Combine state differences, modifying the first diff in place."
function combine!(d::Diff, diffs::Diff...)
    d1 = diffs[1]
    append!(d.add, d1.add)
    append!(d.del, d1.del)
    merge!(d.ops, d1.ops)
    if (length(diffs) > 1) merge!(d, diffs[2:end]) end
    return d
end

"Combine state differences, returning a fresh diff."
function combine(diffs::Diff...)
    return combine!(Diff(), diffs...)
end

"Convert effect formula to a state difference (additions, deletions, etc.)"
function effect_diff(effect::Term, state::Union{State,Nothing}=nothing,
                     domain::Union{Domain,Nothing}=nothing)
    assign_ops = Dict{Symbol,Function}(
        :assign => (x, y) -> y, :increase => +, :decrease => -,
        Symbol("scale-up") => *, Symbol("scale-down") => /)
    diff = Diff()
    if effect.name == :and
        for eff in get_args(effect)
            combine!(diff, effect_diff(eff, state, domain))
        end
    elseif effect.name == :when
        cond, eff = effect.args[1], effect.args[2]
        if isnothing(state) || satisfy([cond], state, domain)[1] == true
            # Return eff if cond is satisfied
            combine!(diff, effect_diff(eff, state, domain))
        end
    elseif effect.name == :forall
        cond, eff = effect.args[1], effect.args[2]
        if !isnothing(state)
            # Find objects matching cond and apply effects for each
            _, subst = satisfy([cond], state, domain; mode=:all)
            for s in subst
                combine!(diff, effect_diff(substitute(eff, s), state, domain))
            end
        else
            push!(diff.add, effect)
        end
    elseif effect.name == :probabilistic
        n_effs = Int(length(get_args(effect))/2)
        r, cum_prob = rand(), 0.0
        for i in 1:n_effs
            # Sample a random effect
            prob, eff = effect.args[2*i-1].name, effect.args[2*i]
            if cum_prob <= r < (cum_prob + prob)
                diff = combine!(diff, effect_diff(eff, state, domain))
            end
            cum_prob += prob
        end
    elseif effect.name in keys(assign_ops)
        term, val = effect.args[1], effect.args[2]
        val = state === nothing ? val : evaluate(val, state, domain)
        diff.ops[term] = (assign_ops[effect.name], val.name)
    elseif effect.name in [:not, :!]
        effect = effect.args[1]
        if !isnothing(state)  # Evaluated all nested functions
            effect = eval_term(effect, Subst(), state.fluents)
        end
        push!(diff.del, effect)
    else
        if !isnothing(state)  # Evaluated all nested functions
            effect = eval_term(effect, Subst(), state.fluents)
        end
        push!(diff.add, effect)
    end
    return diff
end

"Convert precondition formula to a state difference."
function precond_diff(precond::Term, state::Union{State,Nothing}=nothing)
    diff = Diff()
    # TODO: Handle disjunctions and numeric conditions
    if precond.name == :and
        for eff in get_args(precond)
            combine!(diff, precond_diff(eff, state))
        end
    elseif precond.name == :forall
        cond, eff = precond.args[1], precond.args[2]
        if !isnothing(state)
            # Find objects matching cond and apply effects for each
            _, subst = satisfy([cond], state; mode=:all)
            for s in subst
                combine!(diff, precond_diff(substitute(eff, s), state))
            end
        else
            push!(diff.add, precond)
        end
    elseif precond.name in [:not, :!]
        precond = precond.args[1]
        push!(diff.del, precond)
    else
        push!(diff.add, precond)
    end
    return diff
end

"Update a world state (in-place) with a state difference."
function update!(state::State, diff::Diff)
    filter!(c -> !(c in diff.del), state.facts)
    union!(state.facts, diff.add)
    for (term, (op, val)) in diff.ops
        if isa(term, Const)
            oldval = get(state.fluents, term.name, 0)
            state.fluents[term.name] = op(oldval, val)
        elseif isa(term, Compound)
            valdict = get!(state.fluents, term.name, Dict())
            args = Tuple(a.name for a in term.args)
            oldval = get(valdict, args, 0)
            valdict[args] = op(oldval, val)
        end
    end
    return state
end

"Update a world state with a state difference."
function update(state::State, diff::Diff)
    return update!(copy(state), diff)
end

"A (categorical) distribution over possible state differences."
mutable struct DiffDist
    probs::Vector{Float64}
    diffs::Vector{Diff}
end

DiffDist() = DiffDist([1.0], [Diff()])

"Returns Cartesian product of two distributions over state differences."
function product(d1::DiffDist, d2::DiffDist)
    probs, diffs = Float64[], Diff[]
    for (p1, diff1) in zip(d1.probs, d1.diffs)
        for (p2, diff2) in zip(d2.probs, d2.diffs)
            push!(probs, p1 * p2)
            push!(diffs, combine(diff1, diff2))
        end
    end
    return DiffDist(probs, diffs)
end

"Combine distributions over state differences via Cartesian product."
function combine(dists::DiffDist...)
    return foldl(product, dists; init=DiffDist())
end

"Return distribution over possible effects, given a state."
function effect_dist(effect::Term, state::State,
                     domain::Union{Domain,Nothing}=nothing)
    if effect.name == :and
        sub_dists = [effect_dist(arg, state, domain) for arg in effect.args]
        dist = combine(sub_dists...)
    elseif effect.name == :when
        cond, eff = effect.args[1], effect.args[2]
        if satisfy([cond], state, domain)[1] == true
            dist = effect_dist(eff, state, domain)
        end
    elseif effect.name == :forall
        cond, eff = effect.args[1], effect.args[2]
        # Find objects matching cond and apply effects for each
        _, subst = satisfy([cond], state, domain; mode=:all)
        sub_dists = [effect_dist(substitute(eff, s), state, domain)
                     for s in subst]
        dist = combine(sub_dists...)
    elseif effect.name == :probabilistic
        n_effs = Int(length(effect.args)/2)
        probs, diffs = Float64[], Diff[]
        for i in 1:n_effs
            prob, eff = effect.args[2*i-1].name, effect.args[2*i]
            sub_dist = effect_dist(eff, state, domain)
            for (p, diff) in sub_dist
                push!(probs, prob * p)
                push!(diffs, diff)
            end
        end
        dist = DiffDist(probs, diffs)
    else
        # Bottom out at deterministic additions, deletions, or assignments
        diff = effect_diff(effect, state, domain)
        dist = DiffDist([1.0], [diff])
    end
    return dist
end

"Return the effect of a null operation as either a difference or distribution."
function no_effect(as_dist::Bool=false)
    if as_dist
        return DiffDist()
    else
        return Diff()
    end
end

"Update a state with a distribution over state differences."
function update(state::State, dist::DiffDist)
    return [(p, update(state, d)) for (p, d) in zip(dist.probs, dist.diffs)]
end
