module Parser

export parse_domain, parse_problem, parse_action, parse_formula

using ParserCombinator
using FOL
using ..PDDL: Domain, Problem, Action, Event, DEFAULT_REQUIREMENTS

struct Keyword
    name::Symbol
end
Base.show(io::IO, kw::Keyword) = print(io, "KW:", kw.name)

reader_table = Dict{Symbol, Function}()

"Parser combinator for Lisp syntax."
lisp         = Delayed()
floaty_dot   = p"[-+]?[0-9]*\.[0-9]+([eE][-+]?[0-9]+)?[Ff]" > (x -> parse(Float32, x[1:end-1]))
floaty_nodot = p"[-+]?[0-9]*[0-9]+([eE][-+]?[0-9]+)?[Ff]" > (x -> parse(Float32, x[1:end-1]))
floaty       = floaty_dot | floaty_nodot
white_space  = p"([\s\n\r]*(?<!\\);[^\n\r$]+[\n\r\s$]*|[\s\n\r]+)"
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

"Parse to first-order-logic formulas."
function parse_formula(expr::Vector)
    if length(expr) == 0
        return Compound(:and, [])
    elseif length(expr) == 1 && isa(expr[1], Vector)
        return parse_formula(expr[1])
    elseif length(expr) == 1 && isa(expr[1], Var)
        return expr[1]
    elseif length(expr) == 1 && isa(expr[1], Union{Symbol,Number,String})
        return Const(expr[1])
    elseif length(expr) > 1 && isa(expr[1], Symbol)
        name = expr[1]
        args = Term[parse_formula(expr[i:i]) for i in 2:length(expr)]
        return Compound(name, args)
    else
        error("Could not parse $expr to FOL formula.")
    end
end

"Parse predicates with type signatures."
function parse_typed_pred(expr::Vector)
    if length(expr) == 1 && isa(expr[1], Symbol)
        return Const(expr[1]), Symbol[]
    elseif length(expr) > 1 && isa(expr[1], Symbol)
        name = expr[1]
        args, types = parse_typed_vars(expr[2:end])
        return Compound(name, Vector{Term}(args)), types
    else
        error("Could not parse $expr to typed predicate.")
    end
end

"Parse list of typed variables."
function parse_typed_vars(expr::Vector)
    @assert mod(length(expr), 3) == 0 "List of typed vars has wrong length."
    vars, types = Var[], Symbol[]
    for i in 1:3:length(expr)
        @assert (expr[i+1] == :-) "Missing hyphen for variable $(expr[i])."
        push!(vars, expr[i])
        push!(types, expr[i+2])
    end
    return vars, types
end

"Parse list of typed constants."
function parse_typed_consts(expr::Vector)
    @assert mod(length(expr), 3) == 0 "List of typed consts has wrong length."
    consts, types = Const[], Symbol[]
    for i in 1:3:length(expr)
        @assert (expr[i+1] == :-) "Missing hyphen for variable $(expr[i])."
        push!(consts, Const(expr[i]))
        push!(types, expr[i+2])
    end
    return consts, types
end

"Parse planning domain from string."
function parse_domain(str::String)
     expr = parse_one(str, top_level)[1]
     return parse_domain(expr)
end

"Parse planning domain from S-expression."
function parse_domain(expr::Vector)
    @assert (expr[1] == :define) "'define' keyword is missing."
    @assert (expr[2][1] == :domain) "'domain' keyword is missing."
    name = expr[2][2]
    # Parse domain header (requirements, types, etc.)
    defs = Dict(e[1].name => e for e in expr[3:end])
    requirements = parse_requirements(get(defs, :requirements, nothing))
    types = parse_types(get(defs, :types, nothing))
    predicates, predtypes =
        parse_predicates(get(defs, :predicates, nothing), requirements[:typing])
    # Parse domain body (actions, events, etc.)
    defs = [(e[1].name, e) for e in expr[3:end]]
    axioms = Clause[]
    actions = Dict{Symbol,Action}()
    events = Event[]
    for (kw, def) in defs
        if kw in [:axiom, :derived]
            push!(axioms, parse_axiom(def))
        elseif kw == :action
            action = parse_action(def, requirements[:typing])
            actions[action.name] = action
        elseif kw == :event
            push!(events, parse_event(def))
        end
    end
    return Domain(name, requirements, types, predicates, predtypes,
                  axioms, actions, events)
end

"Parse domain requirements."
function parse_requirements(expr::Vector)
    @assert (expr[1].name == :requirements) ":requirements keyword is missing."
    reqs = Dict{Symbol,Bool}(e.name => true for e in expr[2:end])
    return merge(DEFAULT_REQUIREMENTS, reqs)
end
parse_requirements(expr::Nothing) = copy(DEFAULT_REQUIREMENTS)

"Parse type hierarchy."
function parse_types(expr::Vector)
    @assert (expr[1].name == :types) ":types keyword is missing."
    types = Dict{Symbol,Vector{Symbol}}()
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
            accum = Symbol[]
            is_supertype = false
        else
            push!(accum, e)
        end
    end
    return types
end
parse_types(expr::Nothing) = Dict{Symbol,Vector{Symbol}}()

"Parse predicate list."
function parse_predicates(expr::Vector, typing::Bool=false)
    @assert (expr[1].name == :predicates) ":predicates keyword is missing."
    preds, types = Dict{Symbol,Term}(), Dict{Symbol,Vector{Symbol}}()
    for e in expr[2:end]
        pred, ty = typing ? parse_typed_pred(e) : (parse_formula(e), Symbol[])
        preds[pred.name] = pred
        types[pred.name] = ty
    end
    return preds, types
end
parse_predicates(expr::Nothing, typing::Bool=false) =
    Dict{Symbol,Term}(), Dict{Symbol,Vector{Symbol}}()

"Parse axioms (a.k.a. derived predicates)."
function parse_axiom(expr::Vector)
    @assert (expr[1].name in [:axiom, :derived]) ":derived keyword is missing."
    head = parse_formula(expr[2])
    body = parse_formula(expr[3])
    return Clause(head, Term[body])
end

"Parse action definition."
function parse_action(expr::Vector, typing::Bool=false)
    args = Dict(expr[i].name => expr[i+1] for i in 1:2:length(expr))
    @assert (:action in keys(args)) ":action keyword is missing"
    name = args[:action]
    params, types = parse_parameters(get(args, :parameters, []), typing)
    precondition = parse_precondition(args[:precondition])
    effect = parse_effect(args[:effect])
    return Action(name, params, types, Dict{Var,Term}(), precondition, effect)
end

"Parse event definition."
function parse_event(expr::Vector)
    args = Dict(expr[i].name => expr[i+1] for i in 1:2:length(expr))
    @assert (:event in keys(args)) ":action keyword is missing"
    name = args[:event]
    precondition = parse_precondition(args[:precondition])
    effect = parse_effect(args[:effect])
    return Event(name, precondition, effect)
end

"Parse action parameters."
function parse_parameters(expr::Vector, typing::Bool=false)
    return typing ? parse_typed_vars(expr) : (Vector{Var}(expr), Symbol[])
end

"Parse precondition of an action or event."
function parse_precondition(expr::Vector)
    return parse_formula(expr)
end

"Parse effect of an action or event."
function parse_effect(expr::Vector)
    return parse_formula(expr)
end

"Parse planning problem from string."
function parse_problem(str::String, requirements::Dict=Dict())
     expr = parse_one(str, top_level)[1]
     return parse_problem(expr, requirements)
end

"Parse planning problem from S-expression."
function parse_problem(expr::Vector, requirements::Dict=Dict())
    requirements = merge(DEFAULT_REQUIREMENTS, Dict{Symbol,Bool}(requirements))
    @assert (expr[1] == :define) "'define' keyword is missing."
    @assert (expr[2][1] == :problem) "'problem' keyword is missing."
    name = expr[2][2]
    defs = Dict(e[1].name => e for e in expr[3:end])
    domain = defs[:domain][2]
    objects, objtypes =
        parse_objects(get(defs, :objects, nothing), requirements[:typing])
    init = parse_init(defs[:init])
    goal = parse_goal(defs[:goal])
    return Problem(name, domain, objects, objtypes, init, goal)
end

"Parse objects in planning problem."
function parse_objects(expr::Vector, typing::Bool=false)
    @assert (expr[1].name == :objects) ":objects keyword is missing."
    if !typing
        return Const[Const(e) for e in expr[2:end]], Dict{Const,Symbol}()
    else
        objs, types = parse_typed_consts(expr[2:end])
        types = Dict{Const,Symbol}(o => t for (o, t) in zip(objs, types))
        return objs, types
    end
end
parse_objects(expr::Nothing, typing::Bool=false) = Const[], Dict{Const,Symbol}()

"Parse initial formula literals in planning problem."
function parse_init(expr::Vector)
    @assert (expr[1].name == :init) ":init keyword is missing."
    return Clause[Clause(parse_formula(e), []) for e in expr[2:end]]
end

"Parse goal formula in planning problem."
function parse_goal(expr::Vector)
    @assert (expr[1].name == :goal) ":goal keyword is missing."
    return parse_formula(expr[2])
end

end
