"PDDL state description."
mutable struct State
    types::Set{Term} # Object type declarations
    facts::Set{Term} # Boolean-valued fluents
    fluents::Dict{Symbol,Any} # All other fluents
end

"PDDL action description."
struct Action
    name::Symbol # Name of action
    args::Vector{Var} # Action parameters
    types::Vector{Symbol} # Parameter types
    precond::Term # Precondition of action
    effect::Term # Effect of action
end

Action(term::Term, precond::Term, effect::Term) =
    Action(term.name, get_args(term), Symbol[], precond, effect)

Base.:(==)(a1::Action, a2::Action) = (a1.name == a2.name &&
    Set(a1.args) == Set(a2.args) && Set(a1.types) == Set(a2.types) &&
    a1.precond == a2.precond && a1.effect == a2.effect)

"PDDL event description."
struct Event
    name::Symbol # Name of event
    precond::Term # Precondition / trigger of event
    effect::Term # Effect of event
end

Base.:(==)(e1::Event, e2::Event) = (e1.name == e2.name &&
    e1.precond == e2.precond && e1.effect == e2.effect)

"PDDL planning domain with events and axioms."
@kwdef mutable struct Domain
    name::Symbol # Name of domain
    requirements::Dict{Symbol,Bool} = Dict() # PDDL requirements used
    types::Dict{Symbol,Vector{Symbol}} = Dict() # Types and their subtypes
    constants::Vector{Const} = [] # List of constants
    constypes::Dict{Const,Symbol} = Dict() # Types of constants
    predicates::Dict{Symbol,Term} = Dict() # Dictionary of predicates
    predtypes::Dict{Symbol,Vector{Symbol}} = Dict() # Predicate type signatures
    functions::Dict{Symbol,Term} = Dict() # Dictionary of function declarations
    functypes::Dict{Symbol,Vector{Symbol}} = Dict() # Function type signatures
    axioms::Vector{Clause} = [] # Axioms / derived predicates
    actions::Dict{Symbol,Action} = Dict() # Action definitions
    events::Vector{Event} = [] # Event definitions
end

function Domain(name::Symbol, header::Dict{Symbol,Any}, body::Dict{Symbol,Any})
    header = filter(item -> first(item) in fieldnames(Domain), header)
    axioms = Clause[get(body, :axioms, []); get(body, :deriveds, [])]
    body = filter(item -> first(item) in fieldnames(Domain), body)
    body[:axioms] = axioms
    body[:actions] = Dict(act.name => act for act in body[:actions])
    return Domain(;name=name, header..., body...)
end

Base.copy(d::Domain) =
    Domain(; Dict(fn => getfield(d, fn) for fn in fieldnames(typeof(d)))...)

"Get domain constant type declarations as a set of facts."
function get_const_facts(domain::Domain)
  return Set([@julog($ty(:o)) for (o, ty) in domain.constypes])
end

"Get domain constant type declarations as a list of clauses."
function get_const_clauses(domain::Domain)
   return [@julog($ty(:o) <<= true) for (o, ty) in domain.constypes]
end

"Get domain type hierarchy as a list of clauses."
function get_type_clauses(domain::Domain)
    clauses = [[Clause(@julog($ty(X)), Term[@julog($s(X))]) for s in subtys]
               for (ty, subtys) in domain.types if length(subtys) > 0]
    return length(clauses) > 0 ? reduce(vcat, clauses) : Clause[]
end

"Get all proof-relevant Horn clauses for PDDL domain."
function get_clauses(domain::Domain)
   return [domain.axioms; get_const_clauses(domain); get_type_clauses(domain)]
end

"Get list of predicates that are never modified by actions in the domain."
function get_static_predicates(domain::Domain)
    ground = t ->
        substitute(t, Subst(v => Const(gensym()) for v in Julog.get_vars(t)))
    diffs = [effect_diff(ground(act.effect)) for act in values(domain.actions)]
    derived = p -> any(unify(p, ax.head) != nothing for ax in domain.axioms)
    modified = p -> any(contains_term(d, p) for d in diffs)
    return Term[p for p in values(domain.predicates)
                if !derived(p) && !modified(p)]
end

"Get list of functions that are never modified by actions in the domain."
function get_static_functions(domain::Domain)
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

function Problem(state::State, goal::Term=@julog(and()),
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
