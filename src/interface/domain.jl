"PDDL planning domain."
abstract type Domain end

"Returns the name of a domain."
get_name(domain::Domain) = error("Not implemented.")

"Returns domain requirements as a map from requirement names to Boolean values."
get_requirements(domain::Domain) = error("Not implemented.")

"Returns a map from domain types to subtypes."
get_typetree(domain::Domain) = error("Not implemented.")

"Returns an iterator over types in the domain."
get_types(domain::Domain) = keys(get_typetree(domain))

"Returns an iterator over (immediate) subtypes of `type` in the domain."
get_subtypes(domain::Domain, type::Symbol) = get_typetree(domain)[type]

"Returns a map from domain datatypes to Julia types."
get_datatypes(domain::Domain) = error("Not implemented.")

"Returns the Julia type associated with the domain `datatype`."
get_datatype(domain::Domain, datatype::Symbol) = get_datatype(domain)[datatype]

"Returns the list of domain object constants."
get_constants(domain::Domain) = error("Not implemented.")

"Returns a map from domain constants to their types."
get_constypes(domain::Domain) = error("Not implemented.")

"Returns the type of the domain constant `obj`."
get_constype(domain::Domain, obj) = get_constypes[obj]

"Returns a map from predicate names to predicate signatures."
get_predicates(domain::Domain) = error("Not implemented.")

"Returns the signature associated with a predicate `name`."
get_predicate(domain::Domain, name::Symbol) = get_predicates(domain)[name]

"Returns a map from function names to function signatures."
get_functions(domain::Domain) = error("Not implemented.")

"Returns the signature associated with a function `name`."
get_function(domain::Domain, name::Symbol) = get_functions(domain)[name]

"Returns a map from function names to attached function definitions."
get_funcdefs(domain::Domain) = error("Not implemented.")

"Returns the definition associated with a function `name`."
get_funcdef(domain::Domain, name::Symbol) = get_funcdefs(domain)[name]

"Returns a map from domain fluent names to fluent signatures."
get_fluents(domain::Domain) = error("Not implemented.")

"Returns the signature associated with a fluent `name`."
get_fluent(domain::Domain, name::Symbol) = get_fluents(domain)[name]

"Returns a map from names of derived predicates to their corresponding axioms."
get_axioms(domain::Domain) = error("Not implemented.")

"Returns the axiom assocated with a derived predicate `name`."
get_axiom(domain::Domain, name::Symbol) = get_axioms(domain)[name]

"Returns a map from action names to action schemata."
get_actions(domain::Domain) = error("Not implemented.")

"Returns the action schema specified by `name`."
get_action(domain::Domain, name::Symbol) = get_actions(domain)[name]
