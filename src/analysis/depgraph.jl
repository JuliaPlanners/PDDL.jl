struct ActionDependencyNode
    name::Symbol
    args::Vector{Var}
    parents::Vector{Vector{Term}}
    children::Vector{Term}
end

struct AxiomDependencyNode
    name::Symbol
    args::Vector{Var}
    parents::Vector{Vector{Term}}
end

"Action and axiom dependency graph for a planning domain."
struct DependencyGraph
    actions::Dict{Symbol,ActionDependencyNode} # Action nodes
    axioms::Dict{Symbol,AxiomDependencyNode} # Axiom nodes
end

"Construct action and axiom dependency graph for a planning domain."
function dependency_graph(domain::Domain)
    preconds = accumulate_preconds(domain)
    actions = Dict(name => action_dependencies(act, preconds)
                   for (name, act) in get_actions(domain))
    axioms = Dict(name => axiom_dependencies(ax)
                  for (name, ax) in get_axioms(domain))
    return DependencyGraph(actions, axioms)
end

function accumulate_preconds(domain::Domain)
    preconds = Term[]
    for action in values(get_actions(domain))
        conds = to_dnf(get_precond(action)).args |> flatten_conjs
        for c in conds
            if any(unify(c, p) !== nothing for p in preconds) continue end
            push!(preconds, c)
        end
    end
    for axiom in values(get_axioms(domain))
        conds = to_dnf(Compound(:and, axiom.body)).args |> flatten_conjs
        for c in conds
            if any(unify(c, p) !== nothing for p in preconds) continue end
            push!(preconds, c)
        end
    end
    return preconds
end

function action_dependencies(action::Action, preconds)
    parents = get_args.(to_dnf(get_precond(action)).args)
    children = action_children(action, preconds)
    return ActionDependencyNode(get_name(action), get_argvars(action),
                                parents, children)
end

function action_children(action::Action, preconds)
    effect = get_effect(action)
    return effect_children!(effect, preconds, Term[])
end

function effect_children!(effect::Term, preconds, children)
    if effect.name == :and
        for term in effect.args
            effect_children!(term, preconds, children)
        end
    elseif effect.name == :when
        cond, eff = effect.args
        effect_children!(term, preconds, eff)
    elseif effect.name == :forall
        cond, eff = effect.args
        push!(children, effect)
    elseif effect.name == :assign
        term, val = effect.args
        conds = [c for c in preconds if has_subterm(c, term)]
        append!(children, conds)
    elseif effect.name in keys(modify_ops)
        term, val = effect.args
        conds = [c for c in preconds if has_subterm(c, term)]
        append!(children, conds)
    elseif effect.name == :not
        push!(children, effect)
    else
        push!(children, effect)
    end
    return unique!(children)
end

function axiom_dependencies(axiom::Clause)
    parents = get_args.(to_dnf(Compound(:and, axiom.body)).args)
    return AxiomDependencyNode(axiom.head.name, axiom.head.args, parents)
end
