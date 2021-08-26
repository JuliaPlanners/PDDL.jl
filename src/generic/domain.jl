"Generic PDDL planning domain."
@kwdef mutable struct GenericDomain <: InterpretedDomain
    name::Symbol # Name of domain
    requirements::Dict{Symbol,Bool} = Dict() # PDDL requirements used
    types::Dict{Symbol,Vector{Symbol}} = Dict() # Types and their subtypes
    constants::Vector{Const} = [] # List of constants
    constypes::Dict{Const,Symbol} = Dict() # Types of constants
    predicates::Dict{Symbol,Term} = Dict() # Dictionary of predicates
    predtypes::Dict{Symbol,Vector{Symbol}} = Dict() # Predicate type signatures
    functions::Dict{Symbol,Term} = Dict() # Dictionary of function declarations
    functypes::Dict{Symbol,Vector{Symbol}} = Dict() # Function type signatures
    funcdefs::Dict{Symbol,Any} = Dict() # Dictionary of function definitions
    axioms::Dict{Symbol,Clause} = Dict() # Axioms / derived predicates
    actions::Dict{Symbol,Action} = Dict() # Action definitions
    _extras::Dict{Symbol,Any} # Extra fields
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

function Base.propertynames(d::GenericDomain, private=false)
    if !private
        tuple(fieldnames(GenericDomain)..., keys(d._extras)...)
    else
        tuple(filter(f -> f != :_extras, fieldnames(GenericDomain))...,
              keys(d._extras)...)
    end
end

Base.copy(domain::GenericDomain) = deepcopy(domain)

get_requirements(domain::GenericDomain) = domain.requirements

get_types(domain::GenericDomain) = domain.types

get_constants(domain::GenericDomain) = domain.constants

get_predicates(domain::GenericDomain) = domain.predicates

get_functions(domain::GenericDomain) = domain.functions

get_fluents(domain::GenericDomain) = merge(domain.predicates, domain.functions)

get_axioms(domain::GenericDomain) = domain.axioms

get_actions(domain::GenericDomain) = domain.actions

"Get domain constant type declarations as a set of facts."
function get_const_facts(domain::GenericDomain)
  return Set([@julog($ty(:o)) for (o, ty) in domain.constypes])
end

"Get domain constant type declarations as a list of clauses."
function get_const_clauses(domain::GenericDomain)
   return [@julog($ty(:o) <<= true) for (o, ty) in domain.constypes]
end

"Get domain type hierarchy as a list of clauses."
function get_type_clauses(domain::GenericDomain)
    clauses = [[Clause(@julog($ty(X)), Term[@julog($s(X))]) for s in subtys]
               for (ty, subtys) in domain.types if length(subtys) > 0]
    return length(clauses) > 0 ? reduce(vcat, clauses) : Clause[]
end

"Get all proof-relevant Horn clauses for PDDL domain."
function get_clauses(domain::GenericDomain)
   return [collect(values(domain.axioms));
           get_const_clauses(domain);
           get_type_clauses(domain)]
end

"Get list of predicates that are never modified by actions in the domain."
function get_static_predicates(domain::GenericDomain, state::State)
    ground = t ->
        substitute(t, Subst(v => Const(gensym()) for v in Julog.get_vars(t)))
    diffs = [effect_diff(domain, state, ground(act.effect))
             for act in values(domain.actions)]
    derived = p -> any(unify(p, ax.head) !== nothing for ax in domain.axioms)
    modified = p -> any(contains_term(d, p) for d in diffs)
    return Term[p for p in values(domain.predicates)
                if !derived(p) && !modified(p)]
end

"Get list of functions that are never modified by actions in the domain."
function get_static_functions(domain::GenericDomain, state::State)
    ground = t ->
        substitute(t, Subst(v => Const(gensym()) for v in Julog.get_vars(t)))
    diffs = [effect_diff(domain, state, ground(act.effect))
             for act in values(domain.actions)]
    modified = p -> any(contains_term(d, p) for d in diffs)
    return Term[p for p in values(domain.functions) if !modified(p)]
end
