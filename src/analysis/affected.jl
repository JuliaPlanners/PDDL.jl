"Check if term is affected by some action or composed of affected subterms."
function is_affected(term::Term, domain::Domain,
                     affected=infer_affected_fluents(domain))
    fluents = constituents(term, domain)
    return any(term.name in affected)
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
get_affected(effect::Term) = unique!(get_affected!(Symbol[], effect))

"Accumulate affected fluent names given an effect formula."
get_affected!(fluents::Vector{Symbol}, effect::Term) =
    get_affected!(effect.name, fluents, effect)

# Use valsplit to switch on effect expression head
@valsplit function get_affected!(Val(name::Symbol), fluents, effect)
    if is_global_modifier(effect.name)
        push!(fluents, effect.args[1].name)
    else
        push!(fluents, effect.name)
    end
end

get_affected!(::Val{:and}, fluents, effect) =
    (for e in effect.args get_affected!(fluents, e) end; fluents)
get_affected!(::Val{:when}, fluents, effect) =
    get_affected!(fluents, effect.args[2])
get_affected!(::Val{:forall}, fluents, effect) =
    get_affected!(fluents, effect.args[2])
get_affected!(::Val{:assign}, fluents, effect) =
    push!(fluents, effect.args[1].name)
get_affected!(::Val{:not}, fluents, effect) =
    push!(fluents, effect.args[1].name)
