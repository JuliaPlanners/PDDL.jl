"Infer fluents that are never modified by some action in a domain."
function infer_static_fluents(domain::Domain)
    affected = Set(infer_affected_fluents(domain))
    static = setdiff(keys(get_fluents(domain)), affected)
    return collect(static)
end

"Infer fluents that are modified by some action in a domain."
function infer_affected_fluents(domain::Domain)
    affected = Symbol[]
    for action in values(get_actions(domain))
        append!(affected, get_affected(action))
    end
    return unique!(affected)
end

const AFFECTED_FUNCS = Dict{Symbol, Function}()

"Return the names of all fluents affected by an action."
function get_affected(action::Action)
    return get_affected(get_effect(action))
end

function get_affected(effect::Term)
    affected_fn! = get(AFFECTED_FUNCS, effect.name, builtin_affected!)
    return affected_fn!(Symbol[], effect)
end

function builtin_affected!(affected::Vector{Symbol}, effect::Term)
    if effect.name == :and
        for eff in effect.args append!(affected, get_affected(eff)) end
    elseif effect.name == :when
        append!(affected, get_affected(effect.args[2]))
    elseif effect.name == :forall
        append!(affected, get_affected(effect.args[2]))
    elseif effect.name == :assign
        push!(affected, effect.args[1].name)
    elseif effect.name in keys(GLOBAL_MODIFIERS)
        push!(affected, effect.args[1].name)
    elseif effect.name == :not
        push!(affected, effect.args[1].name)
    else
        push!(affected, effect.name)
    end
    return affected
end
