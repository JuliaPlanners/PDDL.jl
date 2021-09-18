"PDDL planning domain."
abstract type Domain end

get_name(domain::Domain) = error("Not implemented.")

get_requirements(domain::Domain) = error("Not implemented.")

get_typetree(domain::Domain) = error("Not implemented.")

get_types(domain::Domain) = keys(get_typetree(domain))

get_subtypes(domain::Domain, name::Symbol) = get_typetree(domain)[name]

get_datatypes(domain::Domain) = error("Not implemented.")

get_datatype(domain::Domain, name::Symbol) = get_datatype(domain)[name]

get_constants(domain::Domain) = error("Not implemented.")

get_constypes(domain::Domain) = error("Not implemented.")

get_constype(domain::Domain, obj) = get_constypes[obj]

get_predicates(domain::Domain) = error("Not implemented.")

get_predicate(domain::Domain, name::Symbol) = get_predicates(domain)[name]

get_functions(domain::Domain) = error("Not implemented.")

get_function(domain::Domain, name::Symbol) = get_functions(domain)[name]

get_funcdefs(domain::Domain) = error("Not implemented.")

get_funcdef(domain::Domain, name::Symbol) = get_funcdefs(domain)[name]

get_fluents(domain::Domain) = error("Not implemented.")

get_fluent(domain::Domain, name::Symbol) = get_fluents(domain)[name]

get_axioms(domain::Domain) = error("Not implemented.")

get_axiom(domain::Domain, name::Symbol) = get_axioms(domain)[name]

get_actions(domain::Domain) = error("Not implemented.")

get_action(domain::Domain, name::Symbol) = get_actions(domain)[name]
