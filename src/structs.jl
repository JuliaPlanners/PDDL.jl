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

"PDDL event description."
struct Event
    name::Symbol # Name of event
    precond::Term # Precondition / trigger of event
    effect::Term # Effect of event
end

"PDDL planning domain with events and axioms."
mutable struct Domain
    name::Symbol # Name of domain
    requirements::Dict{Symbol,Bool} # PDDL requirements used
    types::Dict{Symbol,Vector{Symbol}} # Types and their subtypes
    constants::Vector{Const} # List of constants
    constypes::Dict{Const,Symbol} # Types of constants
    predicates::Dict{Symbol,Term} # Dictionary of predicates
    predtypes::Dict{Symbol,Vector{Symbol}} # Predicate type signatures
    functions::Dict{Symbol,Term} # Dictionary of function declarations
    functypes::Dict{Symbol,Vector{Symbol}} # Function type signatures
    axioms::Vector{Clause} # Axioms / derived predicates
    actions::Dict{Symbol,Action} # Action definitions
    events::Vector{Event} # Event definitions
end

Base.copy(d::Domain) =
    Domain(d.name, d.requirements, d.types, d.constants, d.constypes,
           d.predicates, d.predtypes, d.functions, d.functypes,
           d.axioms, d.actions, d.events)

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
    diffs = [get_diff(ground(act.effect)) for act in values(domain.actions)]
    derived = p -> any(unify(p, ax.head) != nothing for ax in domain.axioms)
    modified = p -> any(contains_term(d, p) for d in diffs)
    return Term[p for p in values(domain.predicates)
                if !derived(p) && !modified(p)]
end

"Get list of functions that are never modified by actions in the domain."
function get_static_functions(domain::Domain)
    ground = t ->
        substitute(t, Subst(v => Const(gensym()) for v in Julog.get_vars(t)))
    diffs = [get_diff(ground(act.effect)) for act in values(domain.actions)]
    modified = p -> any(contains_term(d, p) for d in diffs)
    return Term[p for p in values(domain.functions) if !modified(p)]
end

"PDDL planning problem."
mutable struct Problem
    name::Symbol # Name of problem
    domain::Symbol # Name of associated domain
    objects::Vector{Const} # List of objects
    objtypes::Dict{Const,Symbol} # Types of objects
    init::Vector{Term} # Predicates that hold in initial state
    goal::Term # Goal formula
    metric::Tuple{Int64,Term} # Metric direction (+/-1) and formula
end

Base.copy(p::Problem) =
    Problem(p.name, p.domain, p.objects, p.objtypes, p.init, p.goal, p.metric)

"Get object type declarations as a list of clauses."
function get_obj_clauses(problem::Problem)
    return [@julog($ty(:o) <<= true) for (o, ty) in problem.objtypes]
end

"PDDL state description."
mutable struct State
    types::Set{Term} # Object type declarations
    facts::Set{Term} # Boolean-valued fluents
    fluents::Dict{Symbol,Any} # All other fluents
end

Base.copy(s::State) =
    State(copy(s.types), copy(s.facts), deepcopy(s.fluents))
Base.:(==)(s1::State, s2::State) =
    s1.types == s2.types && s1.facts == s2.facts && s1.fluents == s2.fluents
Base.hash(s::State, h::UInt) =
    hash(s.fluents, hash(s.facts, hash(s.types, h)))
