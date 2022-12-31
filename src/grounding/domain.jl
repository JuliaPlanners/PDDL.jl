"""
    GroundDomain(name, source, actions)

Ground PDDL domain, constructed from a lifted `source` domain, with a dictionary
of ground `actions`.
"""
struct GroundDomain <: Domain
    name::Symbol # Domain name
    source::GenericDomain # Lifted source domain
    actions::Dict{Symbol,GroundActionGroup}
end

get_name(domain::GroundDomain) = domain.name

get_source(domain::GroundDomain) = domain.source

get_requirements(domain::GroundDomain) = get_requirements(domain.source)

get_typetree(domain::GroundDomain) = get_typetree(domain.source)

get_datatypes(domain::GroundDomain) = get_datatypes(domain.source)

get_constants(domain::GroundDomain) = get_constants(domain.source)

get_constypes(domain::GroundDomain) = get_constypes(domain.source)

get_predicates(domain::GroundDomain) = get_predicates(domain.source)

get_functions(domain::GroundDomain) = get_functions(domain.source)

get_funcdefs(domain::GroundDomain) = get_funcdefs(domain.source)

get_fluents(domain::GroundDomain) = get_fluents(domain.source)

get_axioms(domain::GroundDomain) = get_axioms(domain.source)

get_actions(domain::GroundDomain) = domain.actions

"""
    ground(domain::Domain, state::State)
    ground(domain::Domain, problem::Problem)

Grounds a lifted `domain` with respect to a initial `state` or `problem`.
"""
ground(domain::Domain, state::State) =
    ground(get_source(domain), GenericState(state))

ground(domain::Domain, problem::Problem) =
    ground(domain, initstate(domain, problem))

function ground(domain::GenericDomain, state::State)
    statics = infer_static_fluents(domain)
    ground_domain = GroundDomain(domain.name, domain, Dict())
    for (name, act) in get_actions(domain)
        ground_domain.actions[name] = ground(domain, state, act;
                                                statics=statics)
    end
    return ground_domain
end
