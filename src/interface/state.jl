"""
    State

Abstract supertype for symbolic states. A `State` is a symbolic description of
the environment and its objects at a particular point in time. It consists of
a set of objects, and a set of ground fluents (predicates or functions)
with values defined over those objects.
"""
abstract type State end

"""
$(SIGNATURES)

Returns an integer index for specified `state`. Defaults to hashing.
"""
stateindex(domain::Domain, state::State) = hash(state)

"""
    get_objects(state::State, [type::Symbol])
    get_objects(domain::Domain, state::State, type::Symbol)

Returns an iterator over objects in the `state`. If a `type` is specified,
the iterator will contain objects only of that type (but not its subtypes).
If a `domain` is provided, then the iterator will contain all objects of that
type or any of its subtypes.
"""
get_objects(state::State) = error("Not implemented.")
get_objects(state::State, type::Symbol) = error("Not implemented.")

"""
$(SIGNATURES)

Returns a map (dictionary, named tuple, etc.) from state objects to their types.
"""
get_objtypes(state::State) = error("Not implemented.")

"""
$(SIGNATURES)

Returns the type of an `object` in a `state`.
"""
get_objtype(state::State, object) = get_objtypes(state)[object]

"""
$(SIGNATURES)

Returns an iterator over true Boolean predicates in a `state`.
"""
get_facts(state::State) = error("Not implemented.")

"""
$(SIGNATURES)

Gets the value of a (non-derived) fluent.Equivalent to using the index
notation `state[term]`.
"""
get_fluent(state::State, term::Term) = error("Not implemented.")

"""
$(SIGNATURES)

Sets the value of a (non-derived) fluent. Equivalent to using the index
notation `state[term] = val`.
"""
set_fluent!(state::State, val, term::Term) = error("Not implemented.")

"""
$(SIGNATURES)

Returns a map from fluent names to values (false predicates may be omitted).
`Base.pairs` is an alias.
"""
get_fluents(state::State) = error("Not implemented.")

"""
$(SIGNATURES)

Returns the names of fluents in a state (false predicates may be omitted).
`Base.keys` is an alias.
"""
get_fluent_names(state::State) = (k for (k, v) in get_fluents(state))

"""
$(SIGNATURES)

Returns the values of fluents in a state (false predicates may be omitted).
`Base.values` is an alias.
"""
get_fluent_values(state::State) = (v for (k, v) in get_fluents(state))

Base.getindex(state::State, term::Term) = get_fluent(state, term)

Base.setindex!(state::State, val, term::Term) = set_fluent!(state, val, term)

Base.pairs(state::State) = get_fluents(state)

Base.keys(state::State) = get_fluent_names(state)

Base.values(state::State) = get_fluent_values(state)
