## Parsers for PDDL formulas ##

"""
$(SIGNATURES)

Parse to first-order-logic formula.
"""
function parse_formula(expr::Vector; interpolate::Bool = false)
    if length(expr) == 0
        return Const(:true)
    elseif length(expr) == 1
        return parse_term(expr[1])
    elseif length(expr) > 1
        name = expr[1]
        if name in (:exists, :forall)
            # Handle exists and forall separately
            if interpolate
                vars, types = parse_typed_vars(expr[2]; interpolate = true)
                typeconds = [:(Compound($ty, Term[$v]))
                             for (v, ty) in zip(vars, types)]
                cond = length(typeconds) > 1 ?
                    :(Compound(:and, Term[$(typeconds...)])) : typeconds[1]
                body = parse_term(expr[3]; interpolate = true)
                return :(Compound($(QuoteNode(name)), Term[$cond, $body]))
            else
                vars, types = parse_typed_vars(expr[2])
                typeconds =
                    Term[Compound(ty, Term[v]) for (v, ty) in zip(vars, types)]
                cond = length(typeconds) > 1 ?
                    Compound(:and, typeconds) : typeconds[1]
                body = parse_term(expr[3])
                return Compound(name, Term[cond, body])
            end
        else
            # Convert = to == so that Julog can handle equality checks
            name = (name == :(=)) ? :(==) : name
            if interpolate
                name = name isa Symbol ? QuoteNode(name) : name
                args = Any[parse_term(expr[i]; interpolate = true)
                           for i in 2:length(expr)]
                return :(Compound($name, Term[$(args...)]))
            else
                args = Term[parse_term(expr[i]) for i in 2:length(expr)]
                return Compound(name, args)
            end
        end
    else
        error("Could not parse $(unparse(expr)) to PDDL formula.")
    end
end
parse_formula(expr::Union{Symbol,Number,Var}; interpolate::Bool = false) =
    parse_term(expr; interpolate = interpolate)
parse_formula(str::AbstractString; interpolate::Bool = false) =
    parse_formula(parse_string(str); interpolate = interpolate)

function parse_term(expr; interpolate::Bool = false)
    if expr isa Vector
        return parse_formula(expr; interpolate = interpolate)
    elseif expr isa Var
        return expr
    elseif expr isa Union{Symbol,Number,String}
        return Const(expr)
    elseif expr isa Expr
        if interpolate
            return :($expr isa Term ? $expr : Const($expr))
        else
            error("Interpolation only supported in macro parsing of formulas.")
        end
    else
        error("Could not parse $(unparse(expr)) to PDDL term.")
    end
end

"""
$(SIGNATURES)

Parse predicates or function declarations with type signatures.
"""
function parse_declaration(expr::Vector)
    if length(expr) == 1 && isa(expr[1], Symbol)
        return Const(expr[1]), Symbol[]
    elseif length(expr) > 1 && isa(expr[1], Symbol)
        name = expr[1]
        args, types = parse_typed_vars(expr[2:end])
        return Compound(name, Vector{Term}(args)), types
    else
        error("Could not parse $(unparse(expr)) to typed declaration.")
    end
end

"""
$(SIGNATURES)

Parse list of typed expressions.
"""
function parse_typed_list(expr::Vector, T::Type, default, parse_fn;
                          interpolate::Bool = false)
    # TODO : Handle either-types
    terms = Vector{T}()
    types = interpolate ? Union{QuoteNode, Expr}[] : Symbol[]
    count, is_type = 0, false
    for e in expr
        if e == :-
            if is_type error("Repeated hyphens in $(unparse(expr)).") end
            is_type = true
            continue
        elseif is_type
            if interpolate
                e = e isa Symbol ? QuoteNode(e) : :($e::Symbol)
            end
            append!(types, fill(e, count))
            count, is_type = 0, false
        else
            push!(terms, parse_fn(e))
            count += 1
        end
    end
    if interpolate
        default = default isa Symbol ? QuoteNode(default) : :($default::Symbol)
    end
    append!(types, fill(default, count))
    return terms, types
end

"""
$(SIGNATURES)

Parse list of typed variables.
"""
function parse_typed_vars(expr::Vector, default=:object; 
                          interpolate::Bool = false)
    if interpolate
        varcheck(e) = e isa Var ? e : :($e::Var)
        return parse_typed_list(expr, Union{Var, Expr}, default, varcheck;
                                interpolate = true)
    else
        return parse_typed_list(expr, Var, default, identity)
    end
end

"""
$(SIGNATURES)

Parse list of typed constants.
"""
parse_typed_consts(expr::Vector, default=:object) =
    parse_typed_list(expr, Const, default, Const)

"""
$(SIGNATURES)

Parse list of typed declarations.
"""
parse_typed_declarations(expr::Vector, default=:boolean) =
    parse_typed_list(expr, Any, default, parse_declaration)
