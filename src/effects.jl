# Functions for handling effect formulae

"Representation of an effect as additions, deletions, and assignments."
mutable struct Diff
    add::Vector{Term} # List of additions
    del::Vector{Term} # List of deletions
    ops::Dict{Term,Any} # Dictionary of assignment operations
end

Diff() = Diff(Term[], Term[], Dict{Term,Any}())

"Return the effect of a null operation."
no_effect() = Diff()

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
function effect_diff(effect::Term, state::Union{GenericState,Nothing}=nothing,
                     domain::Union{GenericDomain,Nothing}=nothing)
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
        if isnothing(state) || satisfy(domain, state, cond)
            # Return eff if cond is satisfied
            combine!(diff, effect_diff(eff, state, domain))
        end
    elseif effect.name == :forall
        cond, eff = effect.args[1], effect.args[2]
        if !isnothing(state)
            # Find objects matching cond and apply effects for each
            subst = satisfiers(domain, state, cond)
            for s in subst
                combine!(diff, effect_diff(substitute(eff, s), state, domain))
            end
        else
            push!(diff.add, effect)
        end
    elseif effect.name in keys(assign_ops)
        term, val = effect.args[1], effect.args[2]
        val = isnothing(state) ? val : Const(evaluate(domain, state, val))
        diff.ops[term] = (assign_ops[effect.name], val.name)
    elseif effect.name == :not
        effect = effect.args[1]
        if !isnothing(state) # Evaluated all nested functions
            effect = eval_term(effect, Subst(), state.fluents)
        end
        push!(diff.del, effect)
    else
        if !isnothing(state) # Evaluated all nested functions
            effect = eval_term(effect, Subst(), state.fluents)
        end
        push!(diff.add, effect)
    end
    return diff
end

"Convert precondition formula to a state difference."
function precond_diff(precond::Term, state::Union{GenericState,Nothing}=nothing)
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
            subst = satisfiers(domain, state, cond)
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
function update!(state::GenericState, diff::Diff)
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
function update(state::GenericState, diff::Diff)
    return update!(copy(state), diff)
end
