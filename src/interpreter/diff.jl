## Effect differences ##

const EFFECT_FUNCS = Dict{Symbol,Function}()

"Convert effect formula to a state difference (additions, deletions, etc.)"
function effect_diff(domain::Domain, state::State, effect::Term)
    effect_fn! = get(EFFECT_FUNCS, effect.name, add_effect!)
    return effect_fn!(GenericDiff(), domain, state, effect)
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
EFFECT_FUNCS[:not] = del_effect!

function and_effect!(diff::GenericDiff,
                     domain::Domain, state::State, effect::Term)
    for eff in get_args(effect)
        combine!(diff, effect_diff(domain, state, eff))
    end
    return diff
end
EFFECT_FUNCS[:and] = and_effect!

function when_effect!(diff::GenericDiff,
                      domain::Domain, state::State, effect::Term)
    cond, eff = effect.args[1], effect.args[2]
    if !satisfy(domain, state, cond) return diff end
    return combine!(diff, effect_diff(domain, state, eff))
end
EFFECT_FUNCS[:when] = when_effect!

function forall_effect!(diff::GenericDiff,
                        domain::Domain, state::State, effect::Term)
    cond, eff = effect.args[1], effect.args[2]
    for s in satisfiers(domain, state, cond)
        combine!(diff, effect_diff(domain, state, substitute(eff, s)))
    end
    return diff
end
EFFECT_FUNCS[:forall] = forall_effect!

function assign_effect!(diff::GenericDiff,
                        domain::Domain, state::State, effect::Term)
    term, val = effect.args[1], effect.args[2]
    diff.ops[term] = val
    return diff
end
EFFECT_FUNCS[:assign] = assign_effect!

function modify_effect!(diff::GenericDiff,
                        domain::Domain, state::State, effect::Term)
    term, val = effect.args[1], effect.args[2]
    op = GLOBAL_MODIFIERS[effect.name]
    diff.ops[term] = Compound(op, Term[term, val])
    return diff
end
for name in keys(GLOBAL_MODIFIERS)
    EFFECT_FUNCS[name] = modify_effect!
end

## Precondition differences ##

const PRECOND_FUNCS = Dict{Symbol,Function}()

"Convert precondition formula to a state difference."
function precond_diff(domain::Domain, state::State, precond::Term)
    precond_fn! = get(PRECOND_FUNCS, precond.name, add_precond!)
    return precond_fn!(GenericDiff(), domain, state, precond)
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
PRECOND_FUNCS[:not] = del_precond!

function and_precond!(diff::GenericDiff,
                      domain::Domain, state::State, precond::Term)
    for pre in get_args(precond)
        combine!(diff, precond_diff(domain, state, pre))
    end
    return diff
end
PRECOND_FUNCS[:and] = and_precond!

function forall_precond!(diff::GenericDiff,
                         domain::Domain, state::State, precond::Term)
    cond, pre = precond.args[1], precond.args[2]
    for s in satisfiers(domain, state, cond)
        combine!(diff, precond_diff(domain, state, substitute(pre, s)))
    end
    return diff
end
PRECOND_FUNCS[:forall] = forall_precond!
