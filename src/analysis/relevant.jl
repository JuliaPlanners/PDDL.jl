"""
$(SIGNATURES)

Infer fluents that are relevant to some action precondition.
"""
function infer_relevant_fluents(domain::Domain)
    fluents = Symbol[]
    for action in values(get_actions(domain))
        append!(fluents, get_relevant(action))
    end
    return unique!(fluents)
end

"""
$(SIGNATURES)

Infer fluents that are relevant to achieving a set of goal fluents.
"""
function infer_relevant_fluents(domain::Domain, goals::Vector{Symbol},
                                axiom_parents=infer_axiom_hierarchy(domain)[1])
    new_goals = copy(goals)
    for g in goals
        append!(new_goals, get(axiom_parents, g, Symbol[]))
    end
    for action in values(get_actions(domain))
        if any(eff in goals for eff in get_affected(action))
            append!(new_goals, get_relevant(action))
        end
    end
    unique!(new_goals)
    return issubset(new_goals, goals) ?
        new_goals : infer_relevant_fluents(domain, new_goals, axiom_parents)
end

infer_relevant_fluents(domain, goal::Nothing) =
    infer_relevant_fluents(domain)
infer_relevant_fluents(domain, goal::Term) =
    infer_relevant_fluents(domain, [c.name::Symbol for c in constituents(goal, domain)])
infer_relevant_fluents(domain, goals::AbstractVector{<:Term}) =
    infer_relevant_fluents(domain, Compound(:and, goals))

"""
$(SIGNATURES)

Return the names of all fluents relevant to the preconditions of an action.
"""
function get_relevant(action::Action)
    fluents = Symbol[]
    get_relevant_preconds!(fluents, get_precond(action))
    get_relevant_effconds!(fluents, get_effect(action))
    return unique!(fluents)
end

"""
$(SIGNATURES)

Accumulate relevant fluent names given a precondition formula.
"""
get_relevant_preconds!(fluents::Vector{Symbol}, precond::Term) =
    get_relevant_preconds!(precond.name, fluents, precond)

# Use valsplit to switch on precond expression head
@valsplit get_relevant_preconds!(Val(name::Symbol), fluents, precond) =
    push!(fluents, precond.name)
get_relevant_preconds!(::Val{:and}, fluents, precond) =
    (for e in precond.args get_relevant_preconds!(fluents, e) end; fluents)
get_relevant_preconds!(::Val{:or}, fluents, precond) =
    (for e in precond.args get_relevant_preconds!(fluents, e) end; fluents)
get_relevant_preconds!(::Val{:imply}, fluents, precond) =
    (get_relevant_preconds!(fluents, precond.args[1]);
     get_relevant_preconds!(fluents, precond.args[2]))
get_relevant_preconds!(::Val{:forall}, fluents, precond) =
    get_relevant_preconds!(fluents, precond.args[2])
get_relevant_preconds!(::Val{:exists}, fluents, precond) =
    get_relevant_preconds!(fluents, precond.args[2])
get_relevant_preconds!(::Val{:not}, fluents, precond) =
    push!(fluents, precond.args[1].name)

"""
$(SIGNATURES)

Accumulate relevant fluent names given an effect formula.
"""
get_relevant_effconds!(fluents::Vector{Symbol}, effect::Term) =
    get_relevant_effconds!(effect.name, fluents, effect)

# Use valsplit to switch on effect expression head
@valsplit get_relevant_effconds!(Val(name::Symbol), fluents, effect) =
    fluents
get_relevant_effconds!(::Val{:and}, fluents, effect) =
    (for e in effect.args get_relevant_effconds!(fluents, e) end; fluents)
get_relevant_effconds!(::Val{:when}, fluents, effect) =
    (get_relevant_preconds!(fluents, effect.args[1]);
     get_relevant_effconds!(fluents, effect.args[2]))
get_relevant_effconds!(::Val{:forall}, fluents, effect) =
    get_relevant_effconds!(fluents, effect.args[2])
