"Generic PDDL action definition."
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

get_name(action::GenericAction) = action.name

get_argvars(action::GenericAction) = action.args

get_argtypes(action::GenericAction) = action.types

get_precond(action::GenericAction) = action.precond

get_effect(action::GenericAction) = action.effect
