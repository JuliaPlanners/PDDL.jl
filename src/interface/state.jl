"PDDL state description."
abstract type State end

"Returns an integer index for specified `state`. Defaults to hashing."
stateindex(domain::Domain, state::State) = hash(state)

"Returns an iterator over objects in the `state`."
get_objects(state::State) = error("Not implemented.")

"Returns an iterator over objects in the `state` with a particular `type`."
get_objects(state::State, type::Symbol) = error("Not implemented.")

"Returns a map from state objects to their types."
get_objtypes(state::State) = error("Not implemented.")

"Returns the type of an `object` in a `state`."
get_objtype(state::State, object) = get_objtypes(state)[object]

"Returns an iterator over true Boolean predicates in a `state`."
get_facts(state::State) = error("Not implemented.")

"Gets the value of a fluent specified by `term`."
get_fluent(state::State, term::Term) = error("Not implemented.")

"Sets the value of a fluent specified by `term` to `val`."
set_fluent!(state::State, val, term::Term) = error("Not implemented.")

"Returns a map from fluent names to values (false predicates may be omitted)."
get_fluents(state::State) = error("Not implemented.")

"Returns the names of fluents in a state (false predicates may be omitted)."
get_fluent_names(state::State) = (k for (k, v) in get_fluents(state))

"Returns the values of fluents in a state (false predicates may be omitted)."
get_fluent_values(state::State) = (v for (k, v) in get_fluents(state))

Base.getindex(state::State, term::Term) = get_fluent(state, term)

Base.setindex!(state::State, val, term::Term) = set_fluent!(state, val, term)

Base.pairs(state::State) = get_fluents(state)

Base.keys(state::State) = get_fluent_names(state)

Base.values(state::State) = get_fluent_values(state)
