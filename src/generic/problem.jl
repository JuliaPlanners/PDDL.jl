"Generic PDDL planning problem."
@kwdef mutable struct GenericProblem <: Problem
    name::Symbol # Name of problem
    domain::Symbol # Name of associated domain
    objects::Vector{Const} # List of objects
    objtypes::Dict{Const,Symbol} # Types of objects
    init::Vector{Term} # Predicates that hold in initial state
    goal::Term # Goal formula
    metric::Union{Tuple{Int,Term},Nothing} # Metric direction (+/-) and formula
end

function GenericProblem(
    name::Symbol, header::Dict{Symbol,Any}, body::Dict{Symbol,Any}
)
    header = filter(item -> first(item) in fieldnames(GenericProblem), header)
    body = filter(item -> first(item) in fieldnames(GenericProblem), body)
    return GenericProblem(;name=name, header..., body...)
end

function GenericProblem(
    state::State, goal::Term=Compound(:and, []), metric=nothing;
    name=:problem, domain=:domain
)
    objtypes = Dict{Const,Symbol}(get_objtypes(state)...)
    objects = collect(get_objects(state))
    init = Term[]
    for (name, val) in get_fluents(state)
        if val isa Bool && val == true # Handle Boolean predicates
            term = name
        else # Handle non-Boolean fluents
            val = valterm(val) # Express value as term
            term = Compound(:(==), Term[name, val]) # Assignment expression
        end
        push!(init, term)
    end
    return GenericProblem(Symbol(name), Symbol(domain),
                          objects, objtypes, init, goal, metric)
end

Base.copy(problem::GenericProblem) = deepcopy(problem)

get_objects(problem::GenericProblem) = problem.objects

get_objtypes(problem::GenericProblem) = problem.objtypes

get_goal(problem::GenericProblem) = problem.goal

get_metric(problem::GenericProblem) = problem.metric
