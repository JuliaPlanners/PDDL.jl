"Abstractly interpreted PDDL domain."
struct AbstractedDomain{D <: Domain} <: Domain
    domain::D
    interpreter::AbstractInterpreter
end

AbstractedDomain(domain::Domain; options...) =
    AbstractedDomain(domain, AbstractInterpreter(; options...))

Base.copy(domain::AbstractedDomain) = deepcopy(domain)

get_name(domain::AbstractedDomain) = get_name(domain.domain)

get_requirements(domain::AbstractedDomain) = get_requirements(domain.domain)

get_typetree(domain::AbstractedDomain) = get_typetree(domain.domain)

get_constants(domain::AbstractedDomain) = get_constants(domain.domain)

get_constypes(domain::AbstractedDomain) = get_constypes(domain.domain)

get_predicates(domain::AbstractedDomain) = get_predicates(domain.domain)

get_functions(domain::AbstractedDomain) = get_functions(domain.domain)

get_funcdefs(domain::AbstractedDomain) = get_funcdefs(domain.domain)

get_fluents(domain::AbstractedDomain) = get_fluents(domain.domain)

get_axioms(domain::AbstractedDomain) = get_axioms(domain.domain)

get_actions(domain::AbstractedDomain) = get_actions(domain.domain)
