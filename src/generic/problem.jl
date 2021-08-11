"PDDL planning problem."
@kwdef mutable struct GenericProblem <: Problem
    name::Symbol # Name of problem
    domain::Symbol # Name of associated domain
    objects::Vector{Const} # List of objects
    objtypes::Dict{Const,Symbol} # Types of objects
    init::Vector{Term} # Predicates that hold in initial state
    goal::Term # Goal formula
    metric::Union{Tuple{Int,Term},Nothing} # Metric direction (+/-) and formula
end

function GenericProblem(name::Symbol, header::Dict{Symbol,Any}, body::Dict{Symbol,Any})
    header = filter(item -> first(item) in fieldnames(GenericProblem), header)
    body = filter(item -> first(item) in fieldnames(GenericProblem), body)
    return GenericProblem(;name=name, header..., body...)
end

function GenericProblem(state::State, goal::Term=@julog(and()),
                 metric::Union{Tuple{Int,Term},Nothing}=nothing;
                 name=:problem, domain=:domain)
    objtypes = Dict{Const,Symbol}(get_args(t)[1] => t.name for t in state.types)
    objects = collect(keys(objtypes))
    init = Term[get_facts(state); get_assignments(state)]
    return GenericProblem(Symbol(name), Symbol(domain),
                   objects, objtypes, init, goal, metric)
end

Base.copy(p::GenericProblem) =
    GenericProblem(; Dict(fn => getfield(p, fn) for fn in fieldnames(typeof(p)))...)

"Get object type declarations as a list of clauses."
function get_obj_clauses(problem::GenericProblem)
    return [@julog($ty(:o) <<= true) for (o, ty) in problem.objtypes]
end
