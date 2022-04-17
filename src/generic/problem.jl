"Generic PDDL planning problem."
@kwdef mutable struct GenericProblem <: Problem
    name::Symbol # Name of problem
    domain::Symbol = gensym() # Name of associated domain
    objects::Vector{Const} = Const[] # List of objects
    objtypes::Dict{Const,Symbol} = Dict{Const,Symbol}() # Types of objects
    init::Vector{Term} = Term[] # Predicates that hold in initial state
    goal::Term = Compound(:and, []) # Goal formula
    metric::Union{Term,Nothing} = nothing # Metric formula
    constraints::Union{Term,Nothing} = nothing # Constraints formula
end

GenericProblem(problem::GenericProblem) = copy(problem)
function GenericProblem(problem::Problem)
    return GenericProblem(
        get_name(problem),
        get_domain_name(problem),
        collect(Const, get_objects(problem)),
        Dict{Const,Symbol}(pairs(get_objtypes(state))...),
        collect(Term, get_init_terms(problem)),
        get_goal(problem),
        get_metric(problem),
        get_constraints(problem)
    )
end

function GenericProblem(
    name::Symbol, header::Dict{Symbol,Any}, body::Dict{Symbol,Any}
)
    header = filter(item -> first(item) in fieldnames(GenericProblem), header)
    body = filter(item -> first(item) in fieldnames(GenericProblem), body)
    return GenericProblem(;name=name, header..., body...)
end

function GenericProblem(
    state::State;
    domain=:domain,
    name=Symbol(domain, "-problem"),
    goal::Term=Compound(:and, []),
    metric=nothing,
    constraints=nothing,
)
    objtypes = Dict{Const,Symbol}(pairs(get_objtypes(state))...)
    objects = collect(get_objects(state))
    init = Term[]
    for (name, val) in get_fluents(state)
        if val isa Bool && val == true # Handle Boolean predicates
            term = name
        else # Handle non-Boolean fluents
            val = val_to_term(val) # Express value as term
            term = Compound(:(==), Term[name, val]) # Assignment expression
        end
        push!(init, term)
    end
    return GenericProblem(Symbol(name), Symbol(domain),
                          objects, objtypes, init,
                          goal, metric, constraints)
end

Base.copy(problem::GenericProblem) = deepcopy(problem)

get_name(problem::GenericProblem) = problem.name

get_domain_name(problem::GenericProblem) = problem.domain

get_objects(problem::GenericProblem) = problem.objects

get_objtypes(problem::GenericProblem) = problem.objtypes

get_init_terms(problem::GenericProblem) = problem.init

get_goal(problem::GenericProblem) = problem.goal

get_metric(problem::GenericProblem) = problem.metric

get_constraints(problem::GenericProblem) = problem.constraints
