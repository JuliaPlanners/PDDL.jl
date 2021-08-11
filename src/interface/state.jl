"PDDL state description."
abstract type State end

get_objects(::State) = error("Not implemented.")

get_objects(::State, type::Symbol) = error("Not implemented.")

get_objtypes(::State) = error("Not implemented.")

get_value(::State, ::Term) = error("Not implemented.")

get_value(::State, name::Symbol, args...) = error("Not implemented.")

set_value!(::State, val, ::Term) = error("Not implemented.")

set_value!(::State, val, name::Symbol, args...) = error("Not implemented.")

Base.getindex(state::State, term::Term) = get_value(state, term)

Base.setindex!(state::State, val, term::Term) = set_value!(state, val, term)
