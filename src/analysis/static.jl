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

"Check if term is static or composed of static subterms."
function is_static(term::Term, domain::Domain,
                   statics=infer_static_fluents(domain))
    if is_external_func(term, domain)
        return all(is_static(a, domain, statics) for a in term.args)
    else
        return term.name in statics
    end
end

function is_static(term::Const, domain::Domain,
                   statics=infer_static_fluents(domain))
    !is_fluent(term, domain) || term.name in statics
end

"Simplify away static fluents within a `term`."
function simplify_statics(term::Term, domain::Domain, state::State,
                          statics=infer_static_fluents(domain))
    # Simplify predicates if they are static and ground
    if is_static(term, domain, statics) && is_ground(term)
        return Const(evaluate(domain, state, term))
    elseif !(term.name in (:and, :or, :imply, :not))
        return term
    end
    # Simplify logical compounds
    args = Term[simplify_statics(a, domain, state, statics) for a in term.args]
    if term.name == :and
        true_idxs = Int[]
        for (i, a) in enumerate(args)
            a.name == false && return Const(false)
            a.name == true && push!(true_idxs, i)
        end
        length(true_idxs) == length(args) && return Const(true)
        deleteat!(args, true_idxs)
        return length(args) == 1 ? args[1] : Compound(:and, args)
    elseif term.name == :or
        false_idxs = Int[]
        for (i, a) in enumerate(args)
            a.name == true && return Const(true)
            a.name == false && push!(false_idxs, i)
        end
        length(false_idxs) == length(args) && return Const(false)
        deleteat!(args, false_idxs)
        return length(args) == 1 ? args[1] : Compound(:or, args)
    elseif term.name == :imply
        cond, query = args
        cond.name == true && return query
        cond.name == false && return Const(true)
        return Compound(:imply, args)
    elseif term.name == :not
        val = args[1].name
        return val isa Bool ? Const(!val) : Compound(:not, args)
    else
        error("Unrecognized logical operator: $(term.name)")
    end
end
