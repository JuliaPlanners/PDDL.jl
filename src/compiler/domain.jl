abstract type CompiledDomain <: Domain end

get_source(::CompiledDomain) = error("Not implemented.")

function generate_domain_type(domain::Domain, state::State)
    name = pddl_to_type_name(get_name(domain))
    if domain isa AbstractedDomain
        domain_type = gensym("CompiledAbstracted" * name * "Domain")
    else
        domain_type = gensym("Compiled" * name * "Domain")
    end
    domain_typedef = :(struct $domain_type <: CompiledDomain end)
    domain_method_defs = generate_domain_methods(domain, domain_type)
    return (domain_type, domain_typedef, domain_method_defs)
end

function generate_domain_methods(domain::Domain, domain_type::Symbol)
    get_name_def = :(get_name(::$domain_type) = $(QuoteNode(get_name(domain))))
    get_source_def = :(get_source(::$domain_type) = $(QuoteNode(domain)))
    get_requirements_def = :(get_requirements(::$domain_type) =
            $(QuoteNode((; get_requirements(domain)...))))
    get_types_def = :(get_types(::$domain_type) =
        $(QuoteNode((; get_types(domain)...))))
    get_constants_def = :(get_constants(::$domain_type) =
        $(QuoteNode(Tuple(get_constants(domain)))))
    get_constypes_def = :(get_constypes(domain::$domain_type) =
        get_constypes(get_source(domain)))
    get_predicates_def = :(get_predicates(::$domain_type) =
        $(QuoteNode((; get_predicates(domain)...))))
    get_functions_def = :(get_functions(::$domain_type) =
        $(QuoteNode((; get_functions(domain)...))))
    get_funcdefs_def = :(get_funcdefs(::$domain_type) =
        $(QuoteNode((; get_funcdefs(domain)...))))
    get_fluents_def = :(get_fluents(::$domain_type) =
        $(QuoteNode((; get_fluents(domain)...))))
    get_axioms_def = :(get_axioms(::$domain_type) =
        $(QuoteNode((; get_axioms(domain)...))))
    domain_defs = Expr(:block, get_name_def, get_source_def,
        get_requirements_def, get_types_def, get_constants_def,
        get_constypes_def, get_predicates_def, get_functions_def,
        get_funcdefs_def, get_fluents_def, get_axioms_def)
end
