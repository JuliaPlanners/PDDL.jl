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

const effect_funcs = Dict{Symbol,Function}()
const assign_ops = Dict{Symbol,Function}(
    :assign => (x, y) -> y,
    :increase => +,
    :decrease => -,
    Symbol("scale-up") => *,
    Symbol("scale-down") => /
)

"Convert effect formula to a state difference (additions, deletions, etc.)"
function effect_diff(domain::Domain, state::State, effect::Term)
    effect_fn! = get(effect_funcs, effect.name, add_effect!)
    return effect_fn!(Diff(), domain, state, effect)
end

function add_effect!(diff::Diff, domain::Domain, state::State, effect::Term)
    if effect isa Compound # Evaluated all nested functions
        args = Term[a isa Compound ? Const(evaluate(domain, state, a)) : a
                    for a in effect.args]
        effect = Compound(effect.name, args)
    end
    push!(diff.add, effect)
    return diff
end

function del_effect!(diff::Diff, domain::Domain, state::State, effect::Term)
    effect = effect.args[1]
    if effect isa Compound # Evaluated all nested functions
        args = Term[a isa Compound ? Const(evaluate(domain, state, a)) : a
                    for a in effect.args]
        effect = Compound(effect.name, args)
    end
    push!(diff.del, effect)
    return diff
end
effect_funcs[:not] = del_effect!

function and_effect!(diff::Diff, domain::Domain, state::State, effect::Term)
    for eff in get_args(effect)
        combine!(diff, effect_diff(domain, state, eff))
    end
    return diff
end
effect_funcs[:and] = and_effect!

function when_effect!(diff::Diff, domain::Domain, state::State, effect::Term)
    cond, eff = effect.args[1], effect.args[2]
    if !satisfy(domain, state, cond) return diff end
    return combine!(diff, effect_diff(domain, state, eff))
end
effect_funcs[:when] = when_effect!

function forall_effect!(diff::Diff, domain::Domain, state::State, effect::Term)
    cond, eff = effect.args[1], effect.args[2]
    for s in satisfiers(domain, state, cond)
        combine!(diff, effect_diff(domain, state, substitute(eff, s)))
    end
    return diff
end
effect_funcs[:forall] = forall_effect!

function assign_effect!(diff::Diff, domain::Domain, state::State, effect::Term)
    term, val = effect.args[1], effect.args[2]
    diff.ops[term] = (assign_ops[effect.name], evaluate(domain, state, val))
    return diff
end
for name in keys(assign_ops)
    effect_funcs[name] = assign_effect!
end

const precond_funcs = Dict{Symbol,Function}()

"Convert precondition formula to a state difference."
function precond_diff(domain::Domain, state::State, precond::Term)
    precond_fn! = get(precond_funcs, precond.name, add_precond!)
    return precond_fn!(Diff(), domain, state, precond)
end

function add_precond!(diff::Diff, domain::Domain, state::State, precond::Term)
    push!(diff.add, precond)
    return diff
end

function del_precond!(diff::Diff, domain::Domain, state::State, precond::Term)
    push!(diff.del, precond.args[1])
    return diff
end
precond_funcs[:not] = del_precond!

function and_precond!(diff::Diff, domain::Domain, state::State, precond::Term)
    for pre in get_args(precond)
        combine!(diff, precond_diff(domain, state, pre))
    end
    return diff
end
precond_funcs[:and] = and_precond!

function forall_precond!(diff::Diff, domain::Domain, state::State, precond::Term)
    cond, pre = precond.args[1], precond.args[2]
    for s in satisfiers(domain, state, cond)
        combine!(diff, precond_diff(domain, state, substitute(pre, s)))
    end
    return diff
end
precond_funcs[:forall] = forall_precond!

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
