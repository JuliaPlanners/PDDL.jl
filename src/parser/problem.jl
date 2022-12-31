"""
$(SIGNATURES)

Parse PDDL problem description.
"""
parse_problem(expr::Vector) =
    GenericProblem(parse_description(:problem, expr)...)
parse_problem(str::AbstractString) =
    parse_problem(parse_string(str))
@add_top_level(:problem, parse_problem)

"""
$(SIGNATURES)

Parse domain for planning problem.
"""
parse_domain_name(expr::Vector) = expr[2]
@add_header_field(:problem, :domain, parse_domain_name)

"""
$(SIGNATURES)

Parse objects in planning problem.
"""
function parse_objects(expr::Vector)
    @assert (expr[1].name == :objects) ":objects keyword is missing."
    objs, types = parse_typed_consts(expr[2:end])
    types = Dict{Const,Symbol}(o => t for (o, t) in zip(objs, types))
    return (objects=objs, objtypes=types)
end
parse_objects(::Nothing) =
    (objects=Const[], objtypes=Dict{Const,Symbol}())
@add_header_field(:problem, :objects, parse_objects)

"""
$(SIGNATURES)

Parse initial formula literals in planning problem.
"""
function parse_init(expr::Vector)
    @assert (expr[1].name == :init) ":init keyword is missing."
    return [parse_formula(e) for e in expr[2:end]]
end
parse_init(::Nothing) = Term[]
@add_header_field(:problem, :init, parse_init)

"""
$(SIGNATURES)

Parse goal formula in planning problem.
"""
function parse_goal(expr::Vector)
    @assert (expr[1].name == :goal) ":goal keyword is missing."
    return parse_formula(expr[2])
end
parse_goal(::Nothing) = Const(true)
@add_header_field(:problem, :goal, parse_goal)

"""
$(SIGNATURES)

Parse metric expression in planning problem.
"""
function parse_metric(expr::Vector)
    @assert (expr[1].name == :metric) ":metric keyword is missing."
    @assert (expr[2] in (:minimize, :maximize)) "Unrecognized optimization."
    return Compound(expr[2], [parse_formula(expr[3])])
end
parse_metric(expr::Nothing) = nothing
@add_header_field(:problem, :metric, parse_metric)

"""
$(SIGNATURES)

Parse constraints formula in planning problem.
"""
function parse_constraints(expr::Vector)
    @assert (expr[1].name == :constraints) ":constraints keyword is missing."
    return parse_formula(expr[2])
end
parse_constraints(::Nothing) = nothing
@add_header_field(:problem, :constraints, parse_constraints)
