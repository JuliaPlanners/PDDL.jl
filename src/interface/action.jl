"PDDL action definition."
abstract type Action end

get_name(action::Action) = error("Not implemented.")

get_argvars(action::Action) = error("Not implemented.")

get_argtypes(action::Action) = error("Not implemented.")

get_precond(action::Action) = error("Not implemented.")

get_precond(action::Action, args) = error("Not implemented.")

get_precond(domain::Domain, name::Symbol) =
    get_precond(get_actions(domain)[name])

get_precond(domain::Domain, term::Term) =
    get_precond(get_actions(domain)[term.name], term.args)

get_effect(action::Action) = error("Not implemented.")

get_effect(action::Action, args) = error("Not implemented.")

get_effect(domain::Domain, name::Symbol) =
    get_effect(get_actions(domain)[name])

get_effect(domain::Domain, term::Term) =
    get_effect(get_actions(domain)[term.name], term.args)

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
