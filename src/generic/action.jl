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

function get_precond(action::GenericAction, args)
    subst = Subst(k => v for (k, v) in zip(action.args, args))
    return substitute(action.precond, subst)
end

get_effect(action::GenericAction) = action.effect

function get_effect(action::GenericAction, args)
    subst = Subst(k => v for (k, v) in zip(action.args, args))
    return substitute(action.effect, subst)
end

"No-op action."
struct NoOp <: Action end

const no_op = NoOp()

get_name(action::NoOp) = Symbol("--")

get_argvars(action::NoOp) = ()

get_argtypes(action::NoOp) = ()

get_precond(action::NoOp) = Compound(:and, [])

get_precond(action::NoOp, args) = Compound(:and, [])

get_effect(action::NoOp) = Compound(:and, [])

get_effect(action::NoOp, args) = Compound(:and, [])

available(::Domain, state::State, ::NoOp, args) = true

execute(::Domain, state::State, ::NoOp, args; options...) = state

relevant(::Domain, state::State, ::NoOp, args; options...) = false

regress(::Domain, state::State, ::NoOp, args; options...) = state
