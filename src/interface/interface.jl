include("signature.jl")
include("domain.jl")
include("problem.jl")
include("state.jl")
include("action.jl")

"""
    satisfy(domain::Domain, state::State, term::Term)
    satisfy(domain::Domain, state::State, terms::AbstractVector{<:Term})

Returns whether the queried `term` or `terms` can be satisfied in the given
`domain` and `state`.
"""
satisfy(domain::Domain, state::State, term::Term) =
    satisfy(domain, state, [term])
satisfy(domain::Domain, state::State, terms::AbstractVector{<:Term}) =
    error("Not implemented.")

"""
    satisfiers(domain::Domain, state::State, term::Term)
    satisfiers(domain::Domain, state::State, terms::AbstractVector{<:Term})

Returns a list of satisfying substitutions of the queried `term` or `terms`
within the given `domain` and `state`.
"""
satisfiers(domain::Domain, state::State, term::Term) =
    satisfiers(domain, state, [term])
satisfiers(domain::Domain, state::State, terms::AbstractVector{<:Term}) =
    error("Not implemented.")

"""
    evaluate(domain::Domain, state::State, term::Term)

Evaluates a grounded `term` in the given `domain` and `state`. If `term`
refers to a numeric fluent, the value of the fluent is returned.
For logical predicates, `evaluate` is equivalent to `satisfy`.
"""
evaluate(domain::Domain, state::State, term::Term) =
    error("Not implemented.")

"""
    initstate(domain::Domain, problem::Problem)

Construct the initial state for a given planning `domain` and `problem`.
"""
initstate(domain::Domain, problem::Problem) =
    error("Not implemented.")

"""
    transition(domain::Domain, state::State, action::Term)
    transition(domain::Domain, state::State, actions)

Returns the successor to `state` in the given `domain` after applying a single
`action` or a set of `actions` in parallel.
"""
transition(domain::Domain, state::State, action::Term) =
    error("Not implemented.")
transition(domain::Domain, state::State, actions) =
    error("Not implemented.")

"""
    available(domain::Domain, state::State, action::Action, args)
    available(domain::Domain, state::State, action::Term)

Check if an `action` parameterized by `args` can be executed in the given
`state` and `domain`. Action parameters can also be specified as the arguments
of a compound `Term`.
"""
available(domain::Domain, state::State, action::Action, args) =
    error("Not implemented.")
available(domain::Domain, state::State, action::Term) =
    available(domain, state, get_actions(domain)[action.name], action.args)

"""
    available(domain::Domain, state::State)

Return an iterator over available actions in a given `state` and `domain`.
"""
available(domain::Domain, state::State) =
    error("Not implemented.")

"""
    execute(domain::Domain, state::State, action::Action, args)
    execute(domain::Domain, state::State, action::Term)

Execute an `action` parameterized by `args` in the given `state`, returning
the resulting state.  Action parameters can also be specified as the arguments
of a compound `Term`.
"""
execute(domain::Domain, state::State, action::Action, args; options...) =
    error("Not implemented.")
execute(domain::Domain, state::State, action::Term; options...) =
    if action.name == get_name(no_op)
        execute(domain, state, no_op, (); options...)
    else
        execute(domain, state, get_actions(domain)[action.name],
                action.args; options...)
    end

"""
    relevant(domain::Domain, state::State, action::Action, args)
    relevant(domain::Domain, state::State, action::Term)

Check if an `action` parameterized by `args` is relevant (can lead to) a `state`
in the given `domain`. Action parameters can also be specified as the arguments
of a compound `Term`.
"""
relevant(domain::Domain, state::State, action::Action, args) =
    error("Not implemented.")
relevant(domain::Domain, state::State, action::Term) =
    relevant(domain, state, get_actions(domain)[action.name], action.args)

"""
    relevant(domain::Domain, state::State)

Return an iterator over relevant actions in a given `state` and `domain`.
"""
relevant(domain::Domain, state::State) =
    error("Not implemented.")

"""
    regress(domain::Domain, state::State, action::Action, args)
    regress(domain::Domain, state::State, action::Term)

Compute the pre-image of an `action` parameterized by `args` with respect to
a `state`. Action parameters can also be specified as the arguments of a
compound `Term`.
"""
regress(domain::Domain, state::State, action::Action, args; options...)=
    error("Not implemented.")
regress(domain::Domain, state::State, action::Term; options...) =
    if action.name == get_name(no_op)
        regress(domain, state, no_op, (); options...)
    else
        regress(domain, state, get_actions(domain)[action.name],
                action.args; options...)
    end
