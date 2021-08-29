function generate_domain_type(domain::Domain, state::State)
     name = pddl_to_type_name(get_name(domain))
     if domain isa AbstractedDomain
         domain_type = gensym("CompiledAbstracted" * name * "Domain")
     else
         domain_type = gensym("Compiled" * name * "Domain")
     end
     domain_typedef = :(struct $domain_type <: CompiledDomain end)
     get_fluents_def =
        :(get_fluents(::$domain_type) = $(QuoteNode((; get_fluents(domain)...))))
     domain_defs = Expr(:block, get_fluents_def)
     return (domain_type, domain_typedef, domain_defs)
end
