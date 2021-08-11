"PDDL planning domain."
abstract type Domain end

get_requirements(::Domain) = error("Not implemented.")

get_types(::Domain) = error("Not implemented.")

get_constants(::Domain) = error("Not implemented.")

get_predicates(::Domain) = error("Not implemented.")

get_functions(::Domain) = error("Not implemented.")

get_fluents(::Domain) = error("Not implemented.")

get_axioms(::Domain) = error("Not implemented.")

get_actions(::Domain) = error("Not implemented.")

get_events(::Domain) = error("Not implemented.")
