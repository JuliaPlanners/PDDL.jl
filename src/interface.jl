"PDDL planning domain."
abstract type Domain end

"PDDL planning problem."
abstract type Problem end

"PDDL state description."
abstract type State end

"PDDL action definition."
abstract type Action end

"PDDL event definition."
abstract type Event end

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
For logical predicates, `evaluate` is equivalent to `satisfiable`.
"""
evaluate(domain::Domain, state::State, term::Term) =
    error("Not implemented.")

"""
    transition(domain::Domain, state::State, action::Term)
    transition(domain::Domain, state::State, actions)

Returns the successor to `state` in the given `domain` after applying a single
`action` or a set of `actions` in parallel, along with any events triggered
by the effects of those actions.
"""
transition(domain::Domain, state::State, action::Term) =
    error("Not implemented.")
transition(domain::Domain, state::State, actions) =
    error("Not implemented.")

"""
    available(domain::Domain, state::State, action::Term)
    available(domain::Domain, state::State, action::Action, args)

Check whether `action` can be executed in the given `state` and `domain`.
"""
available(domain::Domain, state::State, action::Term) =
    error("Not implemented.")
available(domain::Domain, state::State, action::Action, args) =
    error("Not implemented.")

"""
    available(domain::Domain, state::State)

Return the list of available actions in a given `state` and `domain`.
"""
available(domain::Domain, state::State) =
    error("Not implemented.")

"""
    execute(domain::Domain, state::State, action::Term)
    execute(domain::Domain, state::State, action::Action, args)

Execute `action` in the given `state`. If `action` is an `Action`
definition, `args` must be supplied for the action's parameters.
"""
execute(domain::Domain, state::State, action::Term) =
    error("Not implemented.")
execute(domain::Domain, state::State, action::Action, args) =
    error("Not implemented.")

"""
    relevant(domain::Domain, state::State, action::Term)
    relevant(domain::Domain, state::State, action::Action, args)

Check if an `action` is relevant (can lead to) a `state` in the given `domain`.
"""
relevant(domain::Domain, state::State, action::Term) =
    error("Not implemented.")
relevant(domain::Domain, state::State, action::Action, args) =
    error("Not implemented.")

"""
    relevant(domain::Domain, state::State)

Return the list of relevant actions in a given `state` and `domain`.
"""
relevant(domain::Domain, state::State) =
    error("Not implemented.")

"""
    regress(domain::Domain, state::State, action::Term)
    regress(domain::Domain, state::State, action::Action, args)

Compute the pre-image of an `action` with respect to a `state`. If `action` is
an `Action` definition, `args` must be supplied for the action's parameters.
"""
regress(domain::Domain, state::State, action::Term) =
    error("Not implemented.")
regress(domain::Domain, state::State, action::Action, args) =
    error("Not implemented.")

"""
    trigger(domain::Domain, state::State, event::Event)
    trigger(domain::Domain, state::State, events)

Trigger an `event` or `events` if their preconditions hold in the given `state`
and `domain`.
"""
trigger(domain::Domain, state::State, event::Event) =
    error("Not implemented.")
trigger(domain::Domain, state::State, events) =
    error("Not implemented.")
