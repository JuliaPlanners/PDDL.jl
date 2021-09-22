function generate_eval_expr(domain::Domain, state::State, term::Term,
                            varmap=Dict{Var,Any}(), state_var=:state)
    if (term.name in keys(get_fluents(domain)) || term isa Var)
        return generate_get_expr(domain, state, term, varmap, state_var)
    elseif term isa Const
        return QuoteNode(term.name)
    end
    subexprs = [generate_eval_expr(domain, state, a, varmap, state_var)
                for a in term.args]
    expr = if is_global_func(term)
        op = GLOBAL_FUNCTIONS[term.name]
        Expr(:call, QuoteNode(op), subexprs...)
    else
        error("Unrecognized predicate or operator $(term.name).")
    end
    return expr
end

function generate_quantified_expr(domain::Domain, state::State, term::Term,
                                  varmap=Dict{Var,Any}(), state_var=:state)
    @assert length(term.args) == 2 "$(term.name) takes two arguments"
    varmap = copy(varmap) # Make local copy of variable context
    typeconds, query = flatten_conjs(term.args[1]), term.args[2]
    types, vars = Symbol[], Symbol[]
    for (i, cond) in enumerate(typeconds)
        v = Symbol("o$i") # Create local variable name
        push!(vars, v)
        push!(types, cond.name) # Extract type name
        varmap[cond.args[1]] = :($v.name)
    end
    # Generate query expression with local variable context
    expr = generate_check_expr(domain, state, query, varmap, state_var)
    # Construct iterator over (typed) objects
    v, ty = pop!(vars), QuoteNode(pop!(types))
    expr = :($expr for $v in get_objects(state, $ty))
    while !isempty(types)
        v, ty = pop!(vars), QuoteNode(pop!(types))
        expr = Expr(:flatten, :($expr for $v in get_objects(state, $ty)))
    end
    if Domain isa AbstractedDomain
        accum = term.name == :forall ? :(&) : :(|)
        return :($accum($expr...))
    else
        accum = term.name == :forall ? :all : :any
        return :($accum($expr))
    end
end

function generate_check_expr(domain::Domain, state::State, term::Term,
                             varmap=Dict{Var,Any}(), state_var=:state)
    if (is_global_func(term) || term.name in keys(get_funcdefs(domain)))
        return generate_eval_expr(domain, state, term, varmap, state_var)
    elseif (term.name in keys(get_fluents(domain)) || term isa Var)
        return generate_get_expr(domain, state, term, varmap, state_var)
    elseif term.name in (:forall, :exists)
        return generate_quantified_expr(domain, state, term, varmap, state_var)
    elseif term isa Const
        return QuoteNode(term.name::Bool)
    end
    subexprs = [generate_check_expr(domain, state, a, varmap, state_var)
                for a in term.args]
    expr = if term.name == :and
        foldr((a, b) -> Expr(:&&, a, b), subexprs)
    elseif term.name == :or
        foldr((a, b) -> Expr(:||, a, b), subexprs)
    elseif term.name == :imply
        @assert length(term.args) == 2 "imply takes two arguments"
        :(!$(subexprs[1]) || $(subexprs[2]))
    elseif term.name == :not
        @assert length(term.args) == 1 "not takes one argument"
        :(!$(subexprs[1]))
    else
        error("Unrecognized predicate or operator $(term.name).")
    end
    return expr
end

function generate_check_expr(domain::AbstractedDomain, state::State, term::Term,
                             varmap=Dict{Var,Any}(), state_var=:state)
    if (is_global_func(term) || term.name in keys(get_funcdefs(domain)))
        return generate_eval_expr(domain, state, term, varmap, state_var)
    elseif (term.name in keys(get_fluents(domain)) || term isa Var)
        return generate_get_expr(domain, state, term, varmap, state_var)
    elseif term isa Const
        return QuoteNode(term.name)
    end
    subexprs = [generate_check_expr(domain, state, a, varmap, state_var)
                for a in term.args]
    expr = if term.name == :and
        foldr((a, b) -> Expr(:call, :&, a, b), subexprs)
    elseif term.name == :or
        foldr((a, b) -> Expr(:call, :|, a, b), subexprs)
    elseif term.name == :imply
        @assert length(term.args) == 2 "imply takes two arguments"
        :(!$(subexprs[1]) | $(subexprs[2]))
    elseif term.name == :not
        @assert length(term.args) == 1 "not takes one argument"
        :(!$(subexprs[1]))
    else
        error("Unrecognized predicate or operator $(term.name).")
    end
    return expr
end

function generate_effect_expr(domain::Domain, state::State, term::Term,
                              varmap=Dict{Var,Any}(), state_var=:state)
    expr = if term.name == :and
        subexprs = [generate_effect_expr(domain, state, a, varmap, state_var)
                    for a in term.args]
        Expr(:block, subexprs...)
    elseif term.name == :assign
        @assert length(term.args) == 2 "assign takes two arguments"
        term, val = term.args
        val = generate_eval_expr(domain, state, val, varmap, :prev_state)
        generate_set_expr(domain, state, term, val, varmap, state_var)
    elseif term.name == :not
        @assert length(term.args) == 1 "not takes one argument"
        term = term.args[1]
        @assert term.name in keys(get_predicates(domain)) "unrecognized predicate"
        generate_set_expr(domain, state, term, false, varmap, state_var)
    elseif term.name in keys(GLOBAL_MODIFIERS)
        @assert length(term.args) == 2 "$(term.name) takes two arguments"
        op = GLOBAL_MODIFIERS[term.name]
        term, val = term.args
        prev_val = generate_get_expr(domain, state, term, varmap, :prev_state)
        val = generate_eval_expr(domain, state, val, varmap, :prev_state)
        new_val = Expr(:call, QuoteNode(op), prev_val, val)
        generate_set_expr(domain, state, term, new_val, varmap, state_var)
    elseif term.name in keys(get_predicates(domain))
        generate_set_expr(domain, state, term, true, varmap, state_var)
    else
        error("Unrecognized predicate or operator $(term.name).")
    end
    return expr
end
