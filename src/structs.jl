"PDDL state description."
mutable struct GenericState <: State
    types::Set{Term} # Object type declarations
    facts::Set{Term} # Boolean-valued fluents
    fluents::Dict{Symbol,Any} # All other fluents
end

"PDDL action description."
struct GenericAction <: Action
    name::Symbol # Name of action
    args::Vector{Var} # GenericAction parameters
    types::Vector{Symbol} # Parameter types
    precond::Term # Precondition of action
    effect::Term # Effect of action
end

GenericAction(term::Term, precond::Term, effect::Term) =
    GenericAction(term.name, get_args(term), Symbol[], precond, effect)

Base.:(==)(a1::GenericAction, a2::GenericAction) = (a1.name == a2.name &&
    Set(a1.args) == Set(a2.args) && Set(a1.types) == Set(a2.types) &&
    a1.precond == a2.precond && a1.effect == a2.effect)

"PDDL event description."
struct GenericEvent <: Event
    name::Symbol # Name of event
    precond::Term # Precondition / trigger of event
    effect::Term # Effect of event
end

Base.:(==)(e1::GenericEvent, e2::GenericEvent) = (e1.name == e2.name &&
    e1.precond == e2.precond && e1.effect == e2.effect)

"PDDL planning domain with events and axioms."
@kwdef mutable struct GenericDomain <: Domain
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
    axioms::Vector{Clause} = [] # Axioms / derived predicates
    actions::Dict{Symbol,GenericAction} = Dict() # GenericAction definitions
    events::Vector{GenericEvent} = [] # GenericEvent definitions
    _extras::Dict{Symbol,Any} # Extra fields
end

function GenericDomain(name::Symbol, header::Dict{Symbol,Any}, body::Dict{Symbol,Any})
    h_extras = filter(item -> !(first(item) in fieldnames(GenericDomain)), header)
    b_extras = filter(item -> !(first(item) in fieldnames(GenericDomain)), body)
    extras = merge!(h_extras, b_extras)
    header = filter(item -> first(item) in fieldnames(GenericDomain), header)
    axioms = Clause[get(body, :axioms, []); get(body, :deriveds, [])]
    body = filter(item -> first(item) in fieldnames(GenericDomain), body)
    body[:axioms] = axioms
    body[:actions] = Dict(act.name => act for act in body[:actions])
    return GenericDomain(;name=name, _extras=extras, header..., body...)
end

Base.copy(d::GenericDomain) =
    GenericDomain(; Dict(fn => getfield(d, fn) for fn in fieldnames(typeof(d)))...)

Base.getproperty(d::GenericDomain, s::Symbol) =
    hasfield(GenericDomain, s) ? getfield(d, s) : d._extras[s]

Base.setproperty!(d::GenericDomain, s::Symbol, val) =
    hasfield(GenericDomain, s) && s != :_extras ?
        setfield!(d, s, val) : setindex!(d._extras, val, s)

Base.propertynames(d::GenericDomain, private=false) = private ?
    tuple(fieldnames(GenericDomain)..., keys(d._extras)...) :
    tuple(filter(f->f != :_extras, fieldnames(GenericDomain))..., keys(d._extras)...)

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
   return [domain.axioms; get_const_clauses(domain); get_type_clauses(domain)]
end

"Get list of predicates that are never modified by actions in the domain."
function get_static_predicates(domain::GenericDomain)
    ground = t ->
        substitute(t, Subst(v => Const(gensym()) for v in Julog.get_vars(t)))
    diffs = [effect_diff(ground(act.effect)) for act in values(domain.actions)]
    derived = p -> any(unify(p, ax.head) !== nothing for ax in domain.axioms)
    modified = p -> any(contains_term(d, p) for d in diffs)
    return Term[p for p in values(domain.predicates)
                if !derived(p) && !modified(p)]
end

"Get list of functions that are never modified by actions in the domain."
function get_static_functions(domain::GenericDomain)
    ground = t ->
        substitute(t, Subst(v => Const(gensym()) for v in Julog.get_vars(t)))
    diffs = [effect_diff(ground(act.effect)) for act in values(domain.actions)]
    modified = p -> any(contains_term(d, p) for d in diffs)
    return Term[p for p in values(domain.functions) if !modified(p)]
end

"PDDL planning problem."
@kwdef mutable struct Problem
    name::Symbol # Name of problem
    domain::Symbol # Name of associated domain
    objects::Vector{Const} # List of objects
    objtypes::Dict{Const,Symbol} # Types of objects
    init::Vector{Term} # Predicates that hold in initial state
    goal::Term # Goal formula
    metric::Union{Tuple{Int,Term},Nothing} # Metric direction (+/-) and formula
end

function Problem(name::Symbol, header::Dict{Symbol,Any}, body::Dict{Symbol,Any})
    header = filter(item -> first(item) in fieldnames(Problem), header)
    body = filter(item -> first(item) in fieldnames(Problem), body)
    return Problem(;name=name, header..., body...)
end

function Problem(state::GenericState, goal::Term=@julog(and()),
                 metric::Union{Tuple{Int,Term},Nothing}=nothing;
                 name=:problem, domain=:domain)
    objtypes = Dict{Const,Symbol}(get_args(t)[1] => t.name for t in state.types)
    objects = collect(keys(objtypes))
    init = Term[get_facts(state); get_assignments(state)]
    return Problem(Symbol(name), Symbol(domain),
                   objects, objtypes, init, goal, metric)
end

Base.copy(p::Problem) =
    Problem(; Dict(fn => getfield(p, fn) for fn in fieldnames(typeof(p)))...)

"Get object type declarations as a list of clauses."
function get_obj_clauses(problem::Problem)
    return [@julog($ty(:o) <<= true) for (o, ty) in problem.objtypes]
end
