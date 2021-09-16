"PDDL state description."
abstract type State end

"Returns an integer index for specified `state`. Defaults to hashing."
stateindex(domain::Domain, state::State) = hash(state)

get_objects(state::State) = error("Not implemented.")

get_objects(state::State, type::Symbol) = error("Not implemented.")

get_objtypes(state::State) = error("Not implemented.")

get_objtype(state::State, obj) = get_objtypes[obj]

get_facts(state::State) = error("Not implemented.")

get_fluent(state::State, ::Term) = error("Not implemented.")

get_fluent(state::State, name::Symbol, args...) = error("Not implemented.")

set_fluent!(state::State, val, ::Term) = error("Not implemented.")

set_fluent!(state::State, val, name::Symbol, args...) = error("Not implemented.")

get_fluents(state::State) = error("Not implemented.")

get_fluent_names(state::State) = (k for (k, v) in get_fluents(state))

get_fluent_values(state::State) = (v for (k, v) in get_fluents(state))

Base.getindex(state::State, term::Term) = get_fluent(state, term)

Base.setindex!(state::State, val, term::Term) = set_fluent!(state, val, term)

Base.pairs(state::State) = get_fluents(state)

Base.keys(state::State) = get_fluent_names(state)

Base.values(state::State) = get_fluent_values(state)
