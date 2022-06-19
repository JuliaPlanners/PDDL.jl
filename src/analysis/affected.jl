"Check if term is affected by some action or composed of affected subterms."
function is_affected(term::Term, domain::Domain,
                     affected=infer_affected_fluents(domain))
    if is_external_func(term, domain)
        return all(is_affected(a, domain, statics) for a in term.args)
    else
        return term.name in affected
    end
end

function is_affected(term::Const, domain::Domain,
                     affected=infer_affected_fluents(domain))
    !is_fluent(term, domain) || term.name in affected
end

"Infer fluents that are modified by some action in a domain."
function infer_affected_fluents(domain::Domain)
    # Infer fluents directly changed by actions
    affected = Symbol[]
    for action in values(get_actions(domain))
        append!(affected, get_affected(action))
    end
    # Infer affected derived predicates
    _, children = infer_axiom_hierarchy(domain)
    queue = copy(affected)
    while !isempty(queue)
        fluent = pop!(queue)
        derived = get!(children, fluent, Symbol[])
        filter!(x -> !(x in affected), derived)
        append!(queue, derived)
        append!(affected, derived)
    end
    return unique!(affected)
end

"Return the names of all fluents affected by an action."
get_affected(action::Action) = get_affected(get_effect(action))
get_affected(effect::Term) = get_affected!(effect.name, Symbol[], effect)

# Use valsplit to switch on effect expression head
@valsplit function get_affected!(Val(name::Symbol),
                                 affected::Vector{Symbol}, effect::Term)
    return builtin_affected!(affected, effect)
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
    elseif is_global_modifier(effect.name)
        push!(affected, effect.args[1].name)
    elseif effect.name == :not
        push!(affected, effect.args[1].name)
    else
        push!(affected, effect.name)
    end
    return affected
end
