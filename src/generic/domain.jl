"Generic PDDL planning domain."
@kwdef mutable struct GenericDomain <: Domain
    name::Symbol # Name of domain
    requirements::Dict{Symbol,Bool} = # PDDL requirements
        copy(DEFAULT_REQUIREMENTS)
    typetree::Dict{Symbol,Vector{Symbol}} = # Types and their subtypes
        Dict(:object => Symbol[])
    datatypes::Dict{Symbol,Type} = # Non-object data types
        Dict{Symbol,Type}()
    constants::Vector{Const} = # List of object constants
        Const[]
    constypes::Dict{Const,Symbol} = # Types of constants
        Dict{Const,Symbol}()
    predicates::Dict{Symbol,Signature} = # Predicate signatures
        Dict{Symbol,Signature}()
    functions::Dict{Symbol,Signature} = # Function signatures
        Dict{Symbol,Signature}()
    funcdefs::Dict{Symbol,Any} = # External function implementations
        Dict{Symbol,Any}()
    axioms::Dict{Symbol,Clause} = # Axioms / derived predicates
        Dict{Symbol,Clause}()
    actions::Dict{Symbol,Action} = # Action definitions
        Dict{Symbol,Any}()
    _extras::Dict{Symbol,Any} = # Extra fields for PDDL extensions
        Dict{Symbol,Any}()
end

function GenericDomain(name::Symbol, header::Dict{Symbol,Any}, body::Dict{Symbol,Any})
    h_extras = filter(item -> !(first(item) in fieldnames(GenericDomain)), header)
    b_extras = filter(item -> !(first(item) in fieldnames(GenericDomain)), body)
    extras = merge!(h_extras, b_extras)
    header = filter(item -> first(item) in fieldnames(GenericDomain), header)
    axioms = Clause[get(body, :axioms, []); get(body, :deriveds, [])]
    body = filter(item -> first(item) in fieldnames(GenericDomain), body)
    body[:axioms] = Dict(ax.head.name => ax for ax in axioms)
    body[:actions] = Dict(act.name => act for act in body[:actions])
    return GenericDomain(;name=name, _extras=extras, header..., body...)
end

Base.getproperty(d::GenericDomain, s::Symbol) =
    hasfield(GenericDomain, s) ? getfield(d, s) : d._extras[s]

Base.setproperty!(d::GenericDomain, s::Symbol, val) =
    hasfield(GenericDomain, s) && s != :_extras ?
        setfield!(d, s, val) : setindex!(d._extras, val, s)

function Base.propertynames(d::GenericDomain, private::Bool=false)
    if private
        tuple(fieldnames(GenericDomain)..., keys(d._extras)...)
    else
        tuple(filter(f -> f != :_extras, fieldnames(GenericDomain))...,
              keys(d._extras)...)
    end
end

Base.copy(domain::GenericDomain) = deepcopy(domain)

get_name(domain::GenericDomain) = domain.name

get_source(domain::GenericDomain) = domain

get_requirements(domain::GenericDomain) = domain.requirements

get_typetree(domain::GenericDomain) = domain.typetree

get_datatypes(domain::GenericDomain) = domain.datatypes

get_constants(domain::GenericDomain) = domain.constants

get_constypes(domain::GenericDomain) = domain.constypes

get_predicates(domain::GenericDomain) = domain.predicates

get_functions(domain::GenericDomain) = domain.functions

get_funcdefs(domain::GenericDomain) = domain.funcdefs

get_fluents(domain::GenericDomain) = merge(domain.predicates, domain.functions)

get_axioms(domain::GenericDomain) = domain.axioms

get_actions(domain::GenericDomain) = domain.actions

"""
    include_no_op!(domain::GenericDomain)

Adds the [`NoOp`](@ref) action to the set of available actions.
"""
function include_no_op!(domain::GenericDomain)
    domain.actions[get_name(PDDL.NoOp())] = PDDL.NoOp()
    return domain
end

"""
    include_no_op(domain::GenericDomain)

Returns a copy of the domain with the [`NoOp`](@ref) action added to the set
of available actions.
"""
function include_no_op(domain::GenericDomain)
    return include_no_op!(deepcopy(domain))
end