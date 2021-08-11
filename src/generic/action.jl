"PDDL action description."
struct GenericAction <: Action
    name::Symbol # Name of action
    args::Vector{Var} # GenericAction parameters
    types::Vector{Symbol} # Parameter types
    precond::Term # Precondition of action
    effect::Term # Effect of action
end

GenericAction(term::Term, precond::Term, effect::Term) =
    GenericAction(term.name, get_args(term), Symbol[], precond, effect)

Base.:(==)(a1::GenericAction, a2::GenericAction) = (a1.name == a2.name &&
    Set(a1.args) == Set(a2.args) && Set(a1.types) == Set(a2.types) &&
    a1.precond == a2.precond && a1.effect == a2.effect)

"Get preconditions of an action as a list."
function get_preconditions(act::GenericAction, args::Vector{<:Term};
                           converter::Function=flatten_conjs)
    subst = Subst(var => val for (var, val) in zip(act.args, args))
    precond = substitute(act.precond, subst)
    return converter(precond)
end

get_preconditions(act::GenericAction; converter::Function=flatten_conjs) =
    converter(act.precond)

get_preconditions(act::Term, domain::GenericDomain; kwargs...) =
    get_preconditions(domain.actions[act.name], get_args(act); kwargs...)

"Get effect term of an action with variables substituted by arguments."
function get_effect(act::GenericAction, args::Vector{<:Term})
    subst = Subst(var => val for (var, val) in zip(act.args, args))
    return substitute(act.effect, subst)
end

get_effect(act::Term, domain::GenericDomain) =
    get_effect(domain.actions[act.name], get_args(act))

const no_op = GenericAction(Compound(Symbol("--"), []), @julog(true), @julog(and()))
