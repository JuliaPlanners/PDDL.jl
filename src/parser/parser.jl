module Parser

export parse_domain, parse_problem, parse_pddl, @pddl, @pddl_str
export load_domain, load_problem

using ParserCombinator, Julog
using ..PDDL: GenericDomain, GenericProblem, GenericAction
using ..PDDL: DEFAULT_REQUIREMENTS, IMPLIED_REQUIREMENTS

struct Keyword
    name::Symbol
end
Base.show(io::IO, kw::Keyword) = print(io, "KW:", kw.name)

## Parser combinator from strings to Julia expressions

reader_table = Dict{Symbol, Function}()

"Parser combinator for Lisp syntax."
lisp         = Delayed()
floaty_dot   = p"[-+]?[0-9]*\.[0-9]+([eE][-+]?[0-9]+)?[Ff]" > (x -> parse(Float32, x[1:end-1]))
floaty_nodot = p"[-+]?[0-9]*[0-9]+([eE][-+]?[0-9]+)?[Ff]" > (x -> parse(Float32, x[1:end-1]))
floaty       = floaty_dot | floaty_nodot
white_space  = p"(([\s\n\r]*(?<!\\);[^\n\r$]+[\n\r\s$]*)+|[\s\n\r]+)"
opt_ws       = white_space | e""

doubley      = p"[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?[dD]" > (x -> parse(Float64, x[1:end-1]))

inty         = p"[-+]?\d+" > (x -> parse(Int, x))

uchary       = p"\\(u[\da-fA-F]{4})" > (x -> first(unescape_string(x)))
achary       = p"\\[0-7]{3}" > (x -> unescape_string(x)[1])
chary        = p"\\." > (x -> x[2])

stringy      = p"(?<!\\)\".*?(?<!\\)\"" > (x -> x[2:end-1]) #_0[2:end-1] } #r"(?<!\\)\".*?(?<!\\)"
booly        = p"(true|false)" > (x -> x == "true" ? true : false)
symboly      = p"[^\d():\?{}#'`,@~;~\[\]^\s][^\s:\?()#'`,@~;^{}~\[\]]*" > Symbol
macrosymy    = p"@[^\d():\?{}#'`,@~;~\[\]^\s][^\s:\?()#'`,@~;^{}~\[\]]*" > Symbol

sexpr        = E"(" + ~opt_ws + Repeat(lisp + ~opt_ws) + E")" |> (x -> x)
hashy        = E"#{" + ~opt_ws + Repeat(lisp + ~opt_ws) + E"}" |> (x -> Set(x))
curly        = E"{" + ~opt_ws + Repeat(lisp + ~opt_ws) + E"}" |> (x -> Dict(x[i] => x[i+1] for i = 1:2:length(x)))
dispatchy    = E"#" + symboly + ~opt_ws + lisp |> (x -> reader_table[x[1]](x[2]))
bracket      = E"[" + ~opt_ws + Repeat(lisp + ~opt_ws) + E"]" |> (x -> x)

# Additional combinators to handle PDDL-specific syntax
vary         = p"\?[^\d():\?{}#'`,@~;~\[\]^\s][^\s():\?#'`,@~;^{}~\[\]]*" > (x -> Var(Symbol(uppercasefirst(x[2:end]))))
keywordy     = p":[^\d():\?{}#'`,@~;~\[\]^\s][^\s():\?#'`,@~;^{}~\[\]]*" > (x -> Keyword(Symbol(x[2:end])))

lisp.matcher = doubley | floaty | inty | uchary | achary | chary | stringy | booly |
               vary | keywordy | symboly | macrosymy |
               dispatchy | sexpr | hashy | curly | bracket

top_level    = Repeat(~opt_ws + lisp) + ~opt_ws + Eos()

## Convert expressions back to strings
unparse(expr) = string(expr)
unparse(expr::Vector) = "(" * join(unparse.(expr), " ") * ")"
unparse(expr::Var) = "?" * lowercase(string(expr.name))
unparse(expr::Keyword) = ":" * string(expr.name)

## Parsers for PDDL formulae

"Parse to first-order-logic formula."
function parse_formula(expr::Vector)
    if length(expr) == 0
        return Const(:true)
    elseif length(expr) == 1 && isa(expr[1], Vector)
        return parse_formula(expr[1])
    elseif length(expr) == 1 && isa(expr[1], Var)
        return expr[1]
    elseif length(expr) == 1 && isa(expr[1], Union{Symbol,Number,String})
        return Const(expr[1])
    elseif length(expr) > 1 && isa(expr[1], Symbol)
        name = expr[1]
        if (name in (:exists, :forall) &&
            (any(e == :- for e in expr[2]) || all(e isa Var for e in expr[2])))
            # Handle exists and forall separately
            vars, types = parse_typed_vars(expr[2])
            tpreds = Term[@julog($ty(:v)) for (v, ty) in zip(vars, types)]
            cond = length(tpreds) > 1 ? Compound(:and, tpreds) : tpreds[1]
            body = parse_formula(expr[3:3])
            return Compound(name, Term[cond, body])
        else
            # Convert = to == so that Julog can handle equality checks
            if name == :(=) name = :(==) end
            args = Term[parse_formula(expr[i:i]) for i in 2:length(expr)]
            return Compound(name, args)
        end
    else
        error("Could not parse $(unparse(expr)) to Julog formula.")
    end
end
parse_formula(expr::Symbol) = Const(expr)
parse_formula(str::String) = parse_formula(parse_one(str, top_level)[1])

"Parse predicates with type signatures."
function parse_typed_pred(expr::Vector)
    if length(expr) == 1 && isa(expr[1], Symbol)
        return Const(expr[1]), Symbol[]
    elseif length(expr) > 1 && isa(expr[1], Symbol)
        name = expr[1]
        args, types = parse_typed_vars(expr[2:end])
        return Compound(name, Vector{Term}(args)), types
    else
        error("Could not parse $(unparse(expr)) to typed predicate.")
    end
end

"Parse list of typed variables."
function parse_typed_vars(expr::Vector)
    # TODO : Handle either-types
    vars, types = Var[], Symbol[]
    count, is_type = 0, false
    for e in expr
        if e == :-
            if is_type error("Repeated hyphens in $(unparse(expr)).") end
            is_type = true
            continue
        elseif is_type
            append!(types, fill(e, count))
            count, is_type = 0, false
        else
            push!(vars, e)
            count += 1
        end
    end
    append!(types, fill(:object, count))
    return vars, types
end

"Parse list of typed constants."
function parse_typed_consts(expr::Vector)
    consts, types = Const[], Symbol[]
    count, is_type = 0, false
    for e in expr
        if e == :-
            is_type = true
            continue
        end
        if is_type
            append!(types, repeat([e], count))
            count, is_type = 0, false
        else
            push!(consts, Const(e))
            count += 1
        end
    end
    append!(types, repeat([:object], count))
    return consts, types
end

## Parsers for PDDL domain and problem definitions

"Parsers for top-level PDDL descirptions."
const top_level_parsers = Dict{Symbol,Function}()

"Header field parsers for top-level PDDL descriptions (domains, problems, etc.)."
const head_field_parsers = Dict{Symbol,Dict{Symbol,Function}}(
    :domain => Dict{Symbol,Function}(), :problem => Dict{Symbol,Function}()
)

"Body field parsers for top-level PDDL descriptions (domains, problems, etc.)."
const body_field_parsers = Dict{Symbol,Dict{Symbol,Function}}(
    :domain => Dict{Symbol,Function}(), :problem => Dict{Symbol,Function}()
)

"Parse top-level PDDL descriptions (domains, problems, etc.)."
function parse_description(desc::Symbol, expr::Vector)
    @assert (expr[1] == :define) "'define' keyword is missing."
    @assert (expr[2][1] == desc) "'$desc' keyword is missing."
    name = expr[2][2]
    # Parse description header (requirements, types, etc.)
    header = Dict{Symbol,Any}()
    exprs = Dict(e[1].name => e for e in expr[3:end])
    for (fieldname, parser) in head_field_parsers[desc]
        field = parser(get(exprs, fieldname, nothing))
        if isa(field, NamedTuple)
            merge!(header, Dict(pairs(field)))
        else
            header[fieldname] = field
        end
    end
    # Parse description body (actions, etc.)
    body = Dict{Symbol,Any}()
    exprs = [(e[1].name, e) for e in expr[3:end]]
    for (fieldname, e) in exprs
        if !haskey(body_field_parsers[desc], fieldname) continue end
        parser = body_field_parsers[desc][fieldname]
        fieldname = Symbol(string(fieldname) * "s")
        fields = get!(body, fieldname, [])
        push!(fields, parser(e))
    end
    return name, header, body
end
parse_description(desc::Symbol, str::String) =
    parse_description(desc, parse_one(str, top_level)[1])

"Parse PDDL domain description."
parse_domain(expr::Vector) = GenericDomain(parse_description(:domain, expr)...)
parse_domain(str::String) = parse_domain(parse_one(str, top_level)[1])
parse_domain(expr::Vector, domain_type::Type) =
    domain_type(parse_description(:domain, expr)...)
parse_domain(str::String, domain_type::Type) =
    parse_domain(parse_one(str, top_level)[1], domain_type)
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
    return types
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
    preds, types = Dict{Symbol,Term}(), Dict{Symbol,Vector{Symbol}}()
    for e in expr[2:end]
        pred, ty = parse_typed_pred(e)
        preds[pred.name] = pred
        types[pred.name] = ty
    end
    return (predicates=preds, predtypes=types)
end
parse_predicates(::Nothing) =
    (predicates=Dict{Symbol,Term}(), predtypes=Dict{Symbol,Vector{Symbol}}())
head_field_parsers[:domain][:predicates] = parse_predicates

"Parse list of function (i.e. fluent) declarations."
function parse_functions(expr::Vector)
    @assert (expr[1].name == :functions) ":functions keyword is missing."
    funcs, types = Dict{Symbol,Term}(), Dict{Symbol,Vector{Symbol}}()
    for e in expr[2:end]
        func, ty = parse_typed_pred(e)
        funcs[func.name] = func
        types[func.name] = ty
    end
    return (functions=funcs, functypes=types)
end
parse_functions(::Nothing) =
    (functions=Dict{Symbol,Term}(), functypes=Dict{Symbol,Vector{Symbol}}())
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

"Parse PDDL problem description."
parse_problem(expr::Vector) = GenericProblem(parse_description(:problem, expr)...)
parse_problem(str::String) = parse_problem(parse_one(str, top_level)[1])
top_level_parsers[:problem] = parse_problem
head_field_parsers[:problem][:domain] = e -> e[2]

"Parse objects in planning problem."
function parse_objects(expr::Vector)
    @assert (expr[1].name == :objects) ":objects keyword is missing."
    objs, types = parse_typed_consts(expr[2:end])
    types = Dict{Const,Symbol}(o => t for (o, t) in zip(objs, types))
    return (objects=objs, objtypes=types)
end
parse_objects(::Nothing) =
    (objects=Const[], objtypes=Dict{Const,Symbol}())
head_field_parsers[:problem][:objects] = parse_objects

"Parse initial formula literals in planning problem."
function parse_init(expr::Vector)
    @assert (expr[1].name == :init) ":init keyword is missing."
    return [parse_formula(e) for e in expr[2:end]]
end
parse_init(::Nothing) = Term[]
head_field_parsers[:problem][:init] = parse_init

"Parse goal formula in planning problem."
function parse_goal(expr::Vector)
    @assert (expr[1].name == :goal) ":goal keyword is missing."
    return parse_formula(expr[2])
end
parse_goal(::Nothing) = Const(true)
head_field_parsers[:problem][:goal] = parse_goal

"Parse metric expression in planning problem."
function parse_metric(expr::Vector)
    @assert (expr[1].name == :metric) ":metric keyword is missing."
    @assert (expr[2] in [:minimize, :maximize]) "Unrecognized optimization."
    return (expr[2] == :maximize ? 1 : -1, parse_formula(expr[3]))
end
parse_metric(expr::Nothing) = nothing
head_field_parsers[:problem][:metric] = parse_metric

"Parse to PDDL structure based on initial keyword."
function parse_pddl(expr::Vector)
    if isa(expr[1], Keyword)
        kw = expr[1].name
        for desc in keys(top_level_parsers)
            if kw in keys(head_field_parsers[desc])
                return head_field_parsers[desc][kw](expr)
            elseif kw in keys(body_field_parsers[desc])
                return body_field_parsers[desc][kw](expr)
            end
        end
        error("Keyword $kw not recognized.")
    elseif expr[1] == :define
        kw = expr[2][1]
        return top_level_parsers[kw](expr)
    else
        return parse_formula(expr)
    end
end
parse_pddl(sym::Symbol) = parse_formula(sym)
parse_pddl(str::String) = parse_pddl(parse_one(str, top_level)[1])

"Parse string(s) to PDDL construct."
macro pddl(str::String)
    return parse_pddl(str)
end

macro pddl(strs::String...)
    return collect(parse_pddl.(strs))
end

"Parse string to PDDL construct."
macro pddl_str(str::String)
    return parse_pddl(str)
end

"Load PDDL domain from specified path."
function load_domain(path::String)
    str = open(f->read(f, String), path)
    return parse_domain(str)
end

"Load PDDL problem from specified path."
function load_problem(path::String)
    str = open(f->read(f, String), path)
    return parse_problem(str)
end

end
