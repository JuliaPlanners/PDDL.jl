"PDDL action description."
struct Action
    name::Symbol # Name of action
    args::Vector{Var} # Action parameters
    types::Vector{Symbol} # Parameter types
    refs::Dict{Var,Term} # Deictic references
    precond::Term # Precondition of action
    effect::Term # Effect of action
end

Action(term::Term, precond::Term, effect::Term) =
    Action(term.name, term.args, Symbol[], Dict{Var,Term}(), precond, effect)
Action(term::Term, refs::Dict{Var,Term}, precond::Term, effect::Term) =
    Action(term.name, term.args, Symbol[], refs, precond, effect)

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
    predicates::Dict{Symbol,Term} # Dictionary of predicates
    predtypes::Dict{Symbol,Vector{Symbol}} # Predicate type signatures
    functions::Dict{Symbol,Term} # Dictionary of function declarations
    functypes::Dict{Symbol,Vector{Symbol}} # Function type signatures
    axioms::Vector{Clause} # Axioms / derived predicates
    actions::Dict{Symbol,Action} # Action definitions
    events::Vector{Event} # Event definitions
end

"PDDL planning problem."
mutable struct Problem
    name::Symbol # Name of problem
    domain::Symbol # Name of associated domain
    objects::Vector{Const} # List of objects
    objtypes::Dict{Const,Symbol} # Types of objects
    init::Vector{Clause} # Predicates that hold in initial state
    goal::Term # Goal formula
    metric::Tuple{Int64,Term} # Metric direction (+/-1) and formula
end

"PDDL state description."
mutable struct State
    facts::Vector{Clause}
    fluents::Dict{Symbol,Any}
end
