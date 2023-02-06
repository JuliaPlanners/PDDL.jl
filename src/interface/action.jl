"""
    Action

Abstract supertype for action schemas, which specify the general semantics of
an action parameterized by a set of arguments.
"""
abstract type Action end

"""
$(SIGNATURES)

Returns the name of an action schema.
"""
get_name(action::Action) = error("Not implemented.")

"""
$(SIGNATURES)

Returns the argument variables for an action schema.
"""
get_argvars(action::Action) = error("Not implemented.")

"""
$(SIGNATURES)

Returns the argument types for an action schema.
"""
get_argtypes(action::Action) = error("Not implemented.")

"""
    get_precond(action::Action)
    get_precond(action::Action, args)
    get_precond(domain::Domain, action::Term)

Returns the precondition of an action schema as a `Term`, optionally
parameterized by `args`. Alternatively, an action and its arguments
can be specified as a `Term`.
"""
get_precond(action::Action) = error("Not implemented.")

get_precond(action::Action, args) = error("Not implemented.")

get_precond(domain::Domain, action::Term) =
    get_precond(get_actions(domain)[action.name], action.args)

"""
    get_effect(action::Action)
    get_effect(action::Action, args)
    get_effect(domain::Domain, action::Term)

Returns the effect of an action schema as a `Term`, optionally
parameterized by `args`. Alternatively, an action and its arguments
can be specified as a `Term`.
"""
get_effect(action::Action) = error("Not implemented.")

get_effect(action::Action, args) = error("Not implemented.")

get_effect(domain::Domain, term::Term) =
    get_effect(get_actions(domain)[term.name], term.args)

Base.convert(::Type{Term}, action::Action) =
    convert(Compound, action)

Base.convert(::Type{Compound}, action::Action) =
    Compound(get_name(action), get_argvars(action))

Base.convert(::Type{Const}, action::Action) = isempty(get_argvars(action)) ?
    Const(get_name(action)) : error("Action has arguments.")

"""
    NoOp()

Constructs a no-op action which has no preconditions or effects.
"""
struct NoOp <: Action end

get_name(action::NoOp) = Symbol("--")

get_argvars(action::NoOp) = ()

get_argtypes(action::NoOp) = ()

get_precond(action::NoOp) = Compound(:and, [])

get_precond(action::NoOp, args) = Compound(:and, [])

get_effect(action::NoOp) = Compound(:and, [])

get_effect(action::NoOp, args) = Compound(:and, [])

available(::Domain, state::State, ::NoOp, args) = true

execute(::Domain, state::State, ::NoOp, args; options...) = state

execute!(::Domain, state::State, ::NoOp, args; options...) = state

relevant(::Domain, state::State, ::NoOp, args; options...) = false

regress(::Domain, state::State, ::NoOp, args; options...) = state

regress!(::Domain, state::State, ::NoOp, args; options...) = state

Base.convert(::Type{Term}, ::NoOp) = convert(Compound, NoOp())

Base.convert(::Type{Compound}, act::NoOp) = Compound(get_name(act), Term[])

Base.convert(::Type{Const}, act::NoOp) = Const(get_name(act))

"""
    PDDL.no_op

An alias for pddl"(--)", the action `Term` for a [`NoOp`](@ref) action which has
no preconditions or effects.
"""
const no_op = Compound(get_name(NoOp()), Term[])
