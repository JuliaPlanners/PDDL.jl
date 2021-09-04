## Parsers for PDDL formulas ##

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
        error("Could not parse $(unparse(expr)) to PDDL formula.")
    end
end
parse_formula(expr::Symbol) = Const(expr)
parse_formula(str::AbstractString) = parse_formula(parse_string(str))

"Parse predicates / functions with type signatures."
function parse_typed_fluent(expr::Vector)
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
