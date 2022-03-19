## Effect differences ##

"Convert effect formula to a state difference (additions, deletions, etc.)"
function effect_diff(domain::Domain, state::State, effect::Term)
    return effect_diff!(effect.name, GenericDiff(), domain, state, effect)
end

@valsplit function effect_diff!(Val(name::Symbol), diff::GenericDiff,
                                domain::Domain, state::State, effect::Term)
    # Assume addition by default
    return add_effect!(diff, domain, state, effect)
end

function add_effect!(diff::GenericDiff,
                     domain::Domain, state::State, effect::Term)
    if effect isa Compound # Evaluated all nested functions
        args = Term[a isa Compound ? Const(evaluate(domain, state, a)) : a
                    for a in effect.args]
        effect = Compound(effect.name, args)
    end
    push!(diff.add, effect)
    return diff
end

function del_effect!(diff::GenericDiff,
                     domain::Domain, state::State, effect::Term)
    effect = effect.args[1]
    if effect isa Compound # Evaluated all nested functions
        args = Term[a isa Compound ? Const(evaluate(domain, state, a)) : a
                    for a in effect.args]
        effect = Compound(effect.name, args)
    end
    push!(diff.del, effect)
    return diff
end
effect_diff!(::Val{:not}, diff::Diff, d::Domain, s::State, e::Term) =
    del_effect!(diff, d, s, e)

function and_effect!(diff::GenericDiff,
                     domain::Domain, state::State, effect::Term)
    for eff in get_args(effect)
        combine!(diff, effect_diff(domain, state, eff))
    end
    return diff
end
effect_diff!(::Val{:and}, diff::Diff, d::Domain, s::State, e::Term) =
    and_effect!(diff, d, s, e)

function when_effect!(diff::GenericDiff,
                      domain::Domain, state::State, effect::Term)
    cond, eff = effect.args[1], effect.args[2]
    if !satisfy(domain, state, cond) return diff end
    return combine!(diff, effect_diff(domain, state, eff))
end
effect_diff!(::Val{:when}, diff::Diff, d::Domain, s::State, e::Term) =
    when_effect!(diff, d, s, e)

function forall_effect!(diff::GenericDiff,
                        domain::Domain, state::State, effect::Term)
    cond, eff = effect.args[1], effect.args[2]
    for s in satisfiers(domain, state, cond)
        combine!(diff, effect_diff(domain, state, substitute(eff, s)))
    end
    return diff
end
effect_diff!(::Val{:forall}, diff::Diff, d::Domain, s::State, e::Term) =
    forall_effect!(diff, d, s, e)

function assign_effect!(diff::GenericDiff,
                        domain::Domain, state::State, effect::Term)
    term, val = effect.args[1], effect.args[2]
    diff.ops[term] = val
    return diff
end
effect_diff!(::Val{:assign}, diff::Diff, d::Domain, s::State, e::Term) =
    assign_effect!(diff, d, s, e)

function modify_effect!(diff::GenericDiff,
                        domain::Domain, state::State, effect::Term)
    term, val = effect.args[1], effect.args[2]
    op = modifier_def(effect.name)
    diff.ops[term] = Compound(op, Term[term, val])
    return diff
end
for name in global_modifier_names()
    name = QuoteNode(name)
    @eval effect_diff!(::Val{$name}, diff::Diff, d::Domain, s::State, e::Term) =
        modify_effect!(diff, d, s, e)
end

## Precondition differences ##

const PRECOND_FUNCS = Dict{Symbol,Function}()

"Convert precondition formula to a state difference."
function precond_diff(domain::Domain, state::State, precond::Term)
    return precond_diff!(precond.name, GenericDiff(), domain, state, precond)
end

@valsplit function precond_diff!(Val(name::Symbol), diff::GenericDiff,
                                 domain::Domain, state::State, precond::Term)
    # Assume addition by default
    return add_precond!(diff, domain, state, precond)
end

function add_precond!(diff::GenericDiff,
                      domain::Domain, state::State, precond::Term)
    push!(diff.add, precond)
    return diff
end

function del_precond!(diff::GenericDiff,
                      domain::Domain, state::State, precond::Term)
    push!(diff.del, precond.args[1])
    return diff
end
precond_diff!(::Val{:not}, diff::Diff, d::Domain, s::State, p::Term) =
    del_precond!(diff, d, s, p)

function and_precond!(diff::GenericDiff,
                      domain::Domain, state::State, precond::Term)
    for pre in get_args(precond)
        combine!(diff, precond_diff(domain, state, pre))
    end
    return diff
end
precond_diff!(::Val{:and}, diff::Diff, d::Domain, s::State, p::Term) =
    and_precond!(diff, d, s, p)

function forall_precond!(diff::GenericDiff,
                         domain::Domain, state::State, precond::Term)
    cond, pre = precond.args[1], precond.args[2]
    for s in satisfiers(domain, state, cond)
        combine!(diff, precond_diff(domain, state, substitute(pre, s)))
    end
    return diff
end
precond_diff!(::Val{:forall}, diff::Diff, d::Domain, s::State, p::Term) =
    forall_precond!(diff, d, s, p)
