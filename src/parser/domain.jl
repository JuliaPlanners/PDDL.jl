"Parse PDDL domain description."
parse_domain(expr::Vector) =
    parse_domain(expr, GenericDomain)
parse_domain(str::AbstractString) =
    parse_domain(parse_string(str))
parse_domain(expr::Vector, domain_type::Type) =
    domain_type(parse_description(:domain, expr)...)
parse_domain(str::AbstractString, domain_type::Type) =
    parse_domain(parse_string(str), domain_type)
top_level_parsers[:domain] = parse_domain

"Parse domain requirements."
function parse_requirements(expr::Vector)
    reqs = Dict{Symbol,Bool}(e.name => true for e in expr[2:end])
    reqs = merge(DEFAULT_REQUIREMENTS, reqs)
    unchecked = [k for (k, v) in reqs if v == true]
    while length(unchecked) > 0
        req = pop!(unchecked)
        deps = get(IMPLIED_REQUIREMENTS, req, Symbol[])
        if length(deps) == 0 continue end
        reqs = merge(reqs, Dict{Symbol,Bool}(d => true for d in deps))
        append!(unchecked, deps)
    end
    return reqs
end
parse_requirements(expr::Nothing) = copy(DEFAULT_REQUIREMENTS)
head_field_parsers[:domain][:requirements] = parse_requirements

"Parse type hierarchy."
function parse_types(expr::Vector)
    @assert (expr[1].name == :types) ":types keyword is missing."
    types = Dict{Symbol,Vector{Symbol}}(:object => Symbol[])
    all_subtypes = Set{Symbol}()
    accum = Symbol[]
    is_supertype = false
    for e in expr[2:end]
        if e == :-
            is_supertype = true
            continue
        end
        subtypes = get!(types, e, Symbol[])
        if is_supertype
            append!(subtypes, accum)
            union!(all_subtypes, accum)
            accum = Symbol[]
            is_supertype = false
        else
            push!(accum, e)
        end
    end
    maxtypes = setdiff(keys(types), all_subtypes, [:object])
    append!(types[:object], collect(maxtypes))
    return (typetree=types,)
end
parse_types(expr::Nothing) = Dict{Symbol,Vector{Symbol}}(:object => Symbol[])
head_field_parsers[:domain][:types] = parse_types

"Parse constants in a planning domain."
function parse_constants(expr::Vector)
    @assert (expr[1].name == :constants) ":constants keyword is missing."
    objs, types = parse_typed_consts(expr[2:end])
    types = Dict{Const,Symbol}(o => t for (o, t) in zip(objs, types))
    return (constants=objs, constypes=types)
end
parse_constants(::Nothing) =
    (constants=Const[], constypes=Dict{Const,Symbol}())
head_field_parsers[:domain][:constants] = parse_constants

"Parse predicate list."
function parse_predicates(expr::Vector)
    @assert (expr[1].name == :predicates) ":predicates keyword is missing."
    preds = Dict{Symbol,Signature}()
    declarations, types = parse_typed_declarations(expr[2:end], :boolean)
    for ((term, argtypes), type) in zip(declarations, types)
        if type !== :boolean error("Predicate $term is not boolean.") end
        preds[term.name] = Signature(term, argtypes, type)
    end
    return preds
end
parse_predicates(::Nothing) = Dict{Symbol,Signature}()
head_field_parsers[:domain][:predicates] = parse_predicates

"Parse list of function (i.e. fluent) declarations."
function parse_functions(expr::Vector)
    @assert (expr[1].name == :functions) ":functions keyword is missing."
    funcs = Dict{Symbol,Signature}()
    declarations, types = parse_typed_declarations(expr[2:end], :numeric)
    for ((term, argtypes), type) in zip(declarations, types)
        funcs[term.name] = Signature(term, argtypes, type)
    end
    return funcs
end
parse_functions(::Nothing) = Dict{Symbol,Signature}()
head_field_parsers[:domain][:functions] = parse_functions

"Parse axioms (a.k.a. derived predicates)."
function parse_axiom(expr::Vector)
    @assert (expr[1].name in [:axiom, :derived]) ":derived keyword is missing."
    head = parse_formula(expr[2])
    body = parse_formula(expr[3])
    return Clause(head, Term[body])
end
body_field_parsers[:domain][:axiom] = parse_axiom

"Parse axioms (a.k.a. derived predicates)."
parse_derived(expr::Vector) = parse_axiom(expr)
body_field_parsers[:domain][:derived] = parse_derived

"Parse action definition."
function parse_action(expr::Vector)
    args = Dict(expr[i].name => expr[i+1] for i in 1:2:length(expr))
    @assert (:action in keys(args)) ":action keyword is missing"
    name = args[:action]
    params, types = parse_typed_vars(get(args, :parameters, []))
    precondition = parse_formula(get(args, :precondition, []))
    effect = parse_formula(args[:effect])
    return GenericAction(name, params, types, precondition, effect)
end
body_field_parsers[:domain][:action] = parse_action
