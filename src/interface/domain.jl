"PDDL planning domain."
abstract type Domain end

get_requirements(domain::Domain) = error("Not implemented.")

get_types(domain::Domain) = error("Not implemented.")

get_constants(domain::Domain) = error("Not implemented.")

get_constypes(domain::Domain) = error("Not implemented.")

get_predicates(domain::Domain) = error("Not implemented.")

get_functions(domain::Domain) = error("Not implemented.")

get_funcdefs(domain::Domain) = error("Not implemented.")

get_fluents(domain::Domain) = error("Not implemented.")

get_axioms(domain::Domain) = error("Not implemented.")

get_actions(domain::Domain) = error("Not implemented.")
