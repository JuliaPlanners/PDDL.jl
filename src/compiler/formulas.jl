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
        op = function_def(term.name)
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
        v = gensym("o$i") # Create local variable name
        push!(vars, v)
        push!(types, cond.name) # Extract type name
        varmap[cond.args[1]] = :($v.name)
    end
    # Generate query expression with local variable context
    expr = generate_check_expr(domain, state, query, varmap, state_var)
    # Construct iterator over (typed) objects
    v, ty = pop!(vars), QuoteNode(pop!(types))
    expr = :($expr for $v in get_objects($state_var, $ty))
    while !isempty(types)
        v, ty = pop!(vars), QuoteNode(pop!(types))
        expr = Expr(:flatten, :($expr for $v in get_objects($state_var, $ty)))
    end
    if domain isa AbstractedDomain
        accum = term.name == :forall ? :all4 : :any4
        return :($accum($expr))
    else
        accum = term.name == :forall ? :all : :any
        return :($accum($expr))
    end
end

function generate_axiom_expr(domain::Domain, state::State, term::Term,
                             varmap=Dict{Var,Any}(), state_var=:state)
    axiom = Julog.freshen(get_axiom(domain, term.name))
    subst = unify(axiom.head, term)
    @assert subst !== nothing "Malformed derived predicate: $term"
    body = length(axiom.body) == 1 ? axiom.body[1] : Compound(:and, axiom.body)
    body = to_nnf(substitute(body, subst))
    return generate_check_expr(domain, state, body, varmap, state_var)
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
    elseif term.name in (:forall, :exists)
        return generate_quantified_expr(domain, state, term, varmap, state_var)
    elseif term isa Const
        return QuoteNode(term.name::Bool)
    end
    subexprs = [generate_check_expr(domain, state, a, varmap, state_var)
                for a in term.args]
    expr = if term.name == :and
        generate_abstract_and_stmt(subexprs)
    elseif term.name == :or
        generate_abstract_or_stmt(subexprs)
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

function generate_forall_effect_expr(domain::Domain, state::State, term::Term,
                                     varmap=Dict{Var,Any}(),
                                     state_var=:state, prev_var=:prev_state)
    @assert length(term.args) == 2 "$(term.name) takes two arguments"
    varmap = copy(varmap) # Make local copy of variable context
    typeconds, effect = flatten_conjs(term.args[1]), term.args[2]
    types, vars = Symbol[], Symbol[]
    for (i, cond) in enumerate(typeconds)
        v = Symbol("o$i") # Create local variable name
        push!(vars, v)
        push!(types, cond.name) # Extract type name
        varmap[cond.args[1]] = :($v.name)
    end
    # Generate effect expression with local variable context
    expr = generate_effect_expr(domain, state, effect, varmap,
                                state_var, prev_var)
    # Special case if only one object variable is enumerated over
    if length(vars) == 1
        v, ty = vars[1], QuoteNode(types[1])
        return quote for $v in get_objects($state_var, $ty)
            $expr
        end end
    end
    # Construct iterator over (typed) objects
    obj_exprs = (:(get_objects($state_var, $(QuoteNode(ty)))) for ty in types)
    expr = quote for ($(vars...),) in zip($(obj_exprs...))
        $expr
    end end
    return expr
end

function generate_effect_expr(domain::Domain, state::State, term::Term,
                              varmap=Dict{Var,Any}(),
                              state_var=:state, prev_var=:prev_state)
    expr = if term.name == :and
        subexprs = [generate_effect_expr(domain, state, a, varmap,
                                         state_var, prev_var)
                    for a in term.args]
        Expr(:block, subexprs...)
    elseif term.name == :assign
        @assert length(term.args) == 2 "assign takes two arguments"
        term, val = term.args
        val = generate_eval_expr(domain, state, val, varmap, prev_var)
        generate_set_expr(domain, state, term, val, varmap, state_var)
    elseif term.name == :not
        @assert length(term.args) == 1 "not takes one argument"
        term = term.args[1]
        @assert term.name in keys(get_predicates(domain)) "unrecognized predicate"
        generate_set_expr(domain, state, term, false, varmap, state_var)
    elseif term.name == :when
        @assert length(term.args) == 2 "when takes two arguments"
        cond, effect = term.args
        cond = generate_check_expr(domain, state, cond, varmap, prev_var)
        effect = generate_effect_expr(domain, state, effect, varmap,
                                      state_var, prev_var)
        :(cond = $cond; (cond == true || cond == both) && $effect)
    elseif term.name == :forall
        generate_forall_effect_expr(domain, state, term, varmap,
                                    state_var, prev_var)
    elseif is_global_modifier(term.name)
        @assert length(term.args) == 2 "$(term.name) takes two arguments"
        op = modifier_def(term.name)
        term, val = term.args
        prev_val = generate_get_expr(domain, state, term, varmap, prev_var)
        val = generate_eval_expr(domain, state, val, varmap, prev_var)
        new_val = Expr(:call, op, prev_val, val)
        generate_set_expr(domain, state, term, new_val, varmap, state_var)
    elseif term.name in keys(get_predicates(domain))
        generate_set_expr(domain, state, term, true, varmap, state_var)
    else
        error("Unrecognized predicate or operator $(term.name).")
    end
    return expr
end
