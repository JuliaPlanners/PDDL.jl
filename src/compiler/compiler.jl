abstract type CompiledDomain <: Domain end

abstract type CompiledState <: State end

abstract type CompiledAction <: Action end

function pddl_to_type_name(name)
    words = split(lowercase(string(name)), '-', keepempty=false)
    return join(uppercasefirst.(words))
end

function generate_domain_type(domain::Domain, problem::GenericProblem)
     name = pddl_to_type_name(get_name(domain))
     if domain isa AbstractedDomain
         domain_type = gensym("CompiledAbstracted" * name * "Domain")
     else
         domain_type = gensym("Compiled" * name * "Domain")
     end
     domain_typedef = :(struct $domain_type <: CompiledDomain end)
     return (domain_type, domain_typedef)
end

function generate_state_type(domain::Domain, problem::GenericProblem,
                             domain_type::Symbol)
    # Generate typedef
    state_fields = []
    for (_, pred) in sort(collect(get_predicates(domain)), by=first)
        n_args = length(pred.args)
        type = domain isa AbstractedDomain ?
        (n_args == 0 ? BooleanAbs : Array{BooleanAbs, n_args}) :
            (n_args == 0 ? Bool : BitArray{n_args})
        field = Expr(:(::), pred.name, QuoteNode(type))
        push!(state_fields, field)
    end
    for (_, fn) in sort(collect(get_functions(domain)), by=first)
        n_args = length(fn.args)
        # TODO: Actually use abstractions specified by abstraction function
        type = domain isa AbstractedDomain ?
            (n_args == 0 ? IntervalAbs{Float64} :
                           Array{IntervalAbs{Float64}, n_args}) :
            (n_args == 0 ? Float64 : Array{Float64, n_args})
        field = Expr(:(::), fn.name, QuoteNode(type))
        push!(state_fields, field)
    end
    if domain isa AbstractedDomain
        name = "CompiledAbstracted" * pddl_to_type_name(get_name(domain)) * "State"
    else
        name = "Compiled" * pddl_to_type_name(get_name(domain)) * "State"
    end
    state_type = gensym(name)
    state_typesig = Expr(:(<:), state_type, QuoteNode(CompiledState))
    state_typedef = :(@auto_hash_equals $(Expr(:struct, true, state_typesig,
                                               Expr(:block, state_fields...))))
    # Generate constructor with no arguments
    n_objs = length(problem.objects)
    state_inits = []
    for (_, pred) in sort(collect(get_predicates(domain)), by=first)
        if length(pred.args) == 0
            push!(state_inits, false)
        else
            dims = fill(n_objs, length(pred.args))
            push!(state_inits, :(falses($(dims...))))
        end
    end
    for (_, fn) in sort(collect(get_functions(domain)), by=first)
        if length(fn.args) == 0

            push!(state_inits, 0.0)
        else
            dims = fill(n_objs, length(fn.args))
            if domain isa AbstractedDomain
                push!(state_inits, :(fill(IntervalAbs(0.0), $(dims...))))
            else
                push!(state_inits, :(zeros($(dims...))))
            end
        end
    end
    state_constructor_defs = quote
        $state_type() = $state_type($(state_inits...))
        $state_type(state::$state_type) = copy(state)
    end
    state_copy_def = :(Base.copy(state::$state_type) = deepcopy(state))
    state_method_defs = Expr(:block, state_constructor_defs, state_copy_def)
    return (state_type, state_typedef, state_method_defs)
end

function generate_initstate(domain::Domain, problem::GenericProblem,
                            domain_type::Symbol, state_type::Symbol)
    convert_expr = domain isa AbstractedDomain ?
        :(val = IntervalAbs(val)) : quote end
    return quote
        function initstate(::$domain_type, problem::GenericProblem)
            state = $state_type()
            for term in problem.init
                if term.name == :(==)
                    term, val = term.args[1], term.args[2].name
                    $convert_expr
                else
                    val = true
                end
                if term isa Const
                    setproperty!(state, term.name, val)
                else
                    indices = (objectindex(state, a.name) for a in term.args)
                    getproperty(state, term.name)[indices...] = val
                end
            end
            return state
        end
    end
end

function generate_object_defs(domain::Domain, problem::GenericProblem,
                              domain_type::Symbol, state_type::Symbol)
    object_ids = (; ((o.name, i) for (i, o) in enumerate(problem.objects))...)
    objectindices_def =
        :(objectindices(::$state_type) = $(QuoteNode(object_ids)))
    objectindex_def =
        :(objectindex(state::$state_type, o::Symbol) =
            getfield(objectindices(state), o))
    get_objects_def =
        :(get_objects(::$state_type) = $(QuoteNode(Tuple(problem.objects))))
    return Expr(:block, objectindices_def, objectindex_def, get_objects_def)
end

function generate_get_expr(domain::Domain, problem::GenericProblem,
                           term::Const, varmap=Dict{Var,Any}(), state=:state)
    return :($state.$(term.name))
end

function generate_get_expr(domain::Domain, problem::GenericProblem,
                           term::Var, varmap=Dict{Var,Any}(), state=:state)
    return :($(varmap[term]).name)
end

function generate_get_expr(domain::Domain, problem::GenericProblem,
                           term::Compound, varmap=Dict{Var,Any}(),
                           state=:state)
    object_ids = (; ((o.name, i) for (i, o) in enumerate(problem.objects))...)
    indices = (a isa Var ? :(objectindex(state, $(varmap[a]).name)) :
               object_ids[a.name] for a in term.args)
    return :($state.$(term.name)[$(indices...)])
end

function generate_set_expr(domain::Domain, problem::GenericProblem,
                           term::Const, val, varmap=Dict{Var,Any}(),
                           state=:state)
    if domain isa AbstractedDomain && domain.interpreter.autowiden
        prev_val = generate_get_expr(domain, problem, term, varmap, :prev_state)
        return :($state.$(term.name) = widen($prev_val, $val))
    else
        return :($state.$(term.name) = $val)
    end
end

function generate_set_expr(domain::Domain, problem::GenericProblem,
                           term::Compound, val, varmap=Dict{Var,Any}(),
                           state=:state)
    object_ids = (; ((o.name, i) for (i, o) in enumerate(problem.objects))...)
    indices = (a isa Var ? :(objectindex(state, $(varmap[a]).name)) :
               object_ids[a.name] for a in term.args)
    if domain isa AbstractedDomain && domain.interpreter.autowiden
        prev_val = generate_get_expr(domain, problem, term, varmap, :prev_state)
        return :($state.$(term.name)[$(indices...)] = widen($prev_val, $val))
    else
        return :($state.$(term.name)[$(indices...)] = $val)
    end
end

function generate_eval_expr(domain::Domain, problem::GenericProblem,
                            term::Term, varmap=Dict{Var,Any}(), state=:state)
    if (term.name in keys(get_fluents(domain)) || term isa Var)
        return generate_get_expr(domain, problem, term, varmap, state)
    elseif term isa Const
        return QuoteNode(term.name)
    end
    subexprs = [generate_eval_expr(domain, problem, a, varmap, state)
                for a in term.args]
    expr = if term.name in keys(eval_ops)
        @assert length(term.args) == 2 "$(term.name) takes two arguments"
        op = eval_ops[term.name]
        Expr(:call, QuoteNode(op), subexprs...)
    else
        error("Unrecognized predicate or operator $(term.name).")
    end
    return expr
end

function generate_check_expr(domain::Domain, problem::GenericProblem,
                             term::Term, varmap=Dict{Var,Any}(), state=:state)
    if (term.name in keys(eval_ops) || term.name in keys(get_funcdefs(domain)))
        return generate_eval_expr(domain, problem, term, varmap, state)
    elseif (term.name in keys(get_fluents(domain)) || term isa Var)
        return generate_get_expr(domain, problem, term, varmap, state)
    elseif term isa Const
        return QuoteNode(term.name)
    end
    subexprs = [generate_check_expr(domain, problem, a, varmap, state)
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
    elseif term.name in keys(comp_ops)
        @assert length(term.args) == 2 "$(term.name) takes two arguments"
        op = comp_ops[term.name]
        Expr(:call, QuoteNode(op), subexprs...)
    else
        error("Unrecognized predicate or operator $(term.name).")
    end
    return expr
end

function generate_effect_expr(domain::Domain, problem::GenericProblem,
                              term::Term, varmap=Dict{Var,Any}(), state=:state)
    expr = if term.name == :and
        subexprs = [generate_effect_expr(domain, problem, a, varmap, state)
                    for a in term.args]
        Expr(:block, subexprs...)
    elseif term.name == :assign
        @assert length(term.args) == 2 "assign takes two arguments"
        term, val = term.args
        val = generate_eval_expr(domain, problem, val, varmap, :prev_state)
        generate_set_expr(domain, problem, term, val, varmap, state)
    elseif term.name == :not
        @assert length(term.args) == 1 "not takes one argument"
        term = term.args[1]
        @assert term.name in keys(get_predicates(domain)) "unrecognized predicate"
        generate_set_expr(domain, problem, term, false, varmap, state)
    elseif term.name in keys(modify_ops)
        @assert length(term.args) == 2 "$(term.name) takes two arguments"
        op = modify_ops[term.name]
        term, val = term.args
        prev_val = generate_get_expr(domain, problem, term, varmap, :prev_state)
        val = generate_eval_expr(domain, problem, val, varmap, :prev_state)
        new_val = Expr(:call, QuoteNode(op), prev_val, val)
        generate_set_expr(domain, problem, term, new_val, varmap, state)
    elseif term.name in keys(get_predicates(domain))
        generate_set_expr(domain, problem, term, true, varmap, state)
    else
        error("Unrecognized predicate or operator $(term.name).")
    end
    return expr
end

function generate_evaluate(domain::Domain, problem::GenericProblem,
                           domain_type::Symbol, state_type::Symbol)
    evaluate_def = quote
        function evaluate(domain::$domain_type, state::$state_type, term::Const)
            return term.name in fieldnames($state_type) ?
                getfield(state, term.name) : term.name
        end
        function evaluate(domain::$domain_type, state::$state_type, term::Compound)
            func = get(eval_ops, term.name, get(comp_ops, term.name, nothing))
            val = if func !== nothing
                argvals = (evaluate(domain, state, arg) for arg in term.args)
                func(argvals...)
            else
                indices = (objectindex(state, a.name) for a in term.args)
                getfield(state, term.name)[indices...]
            end
        end
    end
    return evaluate_def
end

function generate_satisfy(domain::Domain, problem::GenericProblem,
                          domain_type::Symbol, state_type::Symbol)
    satisfy_def = quote
        function satisfy(::$domain_type, state::$state_type, term::Const)
            return getfield(state, term.name)
        end
        function satisfy(domain::$domain_type, state::$state_type, term::Compound)
            val = if term.name == :and
                all(satisfy(domain, state, a) for a in term.args)
            elseif term.name == :or
                any(satisfy(domain, state, a) for a in term.args)
            elseif term.name == :imply
                !satisfy(domain, state, term.args[1]) |
                satisfy(domain, state, term.args[2])
            elseif term.name == :not
                !satisfy(domain, state, term.args[1])
            elseif term.name in keys(comp_ops)
                comp_ops[term.name](evaluate(domain, state, term.args[1]),
                                    evaluate(domain, state, term.args[2]))
            elseif any(a isa Var for a in term.args)
                missing
            else
                evaluate(domain, state, term)
            end
            return val
        end
        function satisfy(domain::$domain_type, state::$state_type,
                         terms::AbstractVector{<:Term})
            return all(satisfy(domain, state, t) for t in terms)
        end
    end
    return satisfy_def
end

function generate_action_defs(domain::Domain, problem::GenericProblem,
                              domain_type::Symbol, state_type::Symbol)
    available_def =
        generate_available(domain, problem, domain_type, state_type)
    execute_def =
        generate_execute(domain, problem, domain_type, state_type)
    all_action_defs = [available_def, execute_def]
    all_action_names = sort(collect(keys(get_actions(domain))))
    all_action_types = Symbol[]
    for name in all_action_names
        action_defs =
            generate_action_defs(domain, problem, domain_type, state_type, name)
        push!(all_action_types, action_defs[1])
        append!(all_action_defs, action_defs[2:end])
    end
    action_map = Expr(:tuple, (Expr(:(=), n, Expr(:call, act)) for (n, act)
                               in zip(all_action_names, all_action_types))...)
    get_actions_def = :(get_actions(::$domain_type) = $action_map)
    push!(all_action_defs, get_actions_def)
    return Expr(:block, all_action_defs...)
end

function generate_action_defs(domain::Domain, problem::GenericProblem,
                              domain_type::Symbol, state_type::Symbol,
                              action_name::Symbol)
    action_type = gensym("Compiled" * pddl_to_type_name(action_name) * "Action")
    action_typedef = :(struct $action_type <: CompiledAction end)
    groundargs_def =
        generate_groundargs(domain, problem, domain_type, state_type,
                            action_name, action_type)
    available_def =
        generate_available(domain, problem, domain_type, state_type,
                           action_name, action_type)
    execute_def =
        generate_execute(domain, problem, domain_type, state_type,
                         action_name, action_type)
    return (action_type, action_typedef,
            groundargs_def, available_def, execute_def)
end

function generate_groundargs(domain::Domain, problem::GenericProblem,
                             domain_type::Symbol, state_type::Symbol,
                             action_name::Symbol, action_type::Symbol)
    action = get_actions(domain)[action_name]
    objects_exprs = [:(get_objects(state)) for i in 1:length(action.args)]
    iter_expr = :(Iterators.product($(objects_exprs...)))
    groundargs_def = quote
        function groundargs(domain::$domain_type, state::$state_type,
                            action::$action_type)
            return $iter_expr
        end
    end
    return groundargs_def
end

function generate_available(domain::Domain, problem::GenericProblem,
                            domain_type::Symbol, state_type::Symbol,
                            action_name::Symbol, action_type::Symbol)
    action = get_actions(domain)[action_name]
    varmap = Dict(a => :(args[$i]) for (i, a) in enumerate(action.args))
    precond = generate_check_expr(domain, problem, action.precond, varmap)
    available_def = quote
        function available(domain::$domain_type, state::$state_type,
                           action::$action_type, args)
            $precond
        end
    end
    return available_def
end

function generate_available(domain::Domain, problem::GenericProblem,
                            domain_type::Symbol, state_type::Symbol)
    available_def = quote
        function available(domain::$domain_type, state::$state_type, term::Term)
            available(domain, state, get_actions(domain)[term.name], term.args)
        end
        function available(domain::$domain_type, state::$state_type)
            f= named_action -> begin
                name, action = named_action
                grounded_args = groundargs(domain, state, action)
                return (Compound(name, collect(args)) for args in grounded_args
                        if available(domain, state, action, args))
            end
            actions = Base.Generator(f, pairs(get_actions(domain)))
            return Iterators.flatten(actions)
        end
    end
    return available_def
end

function generate_execute(domain::Domain, problem::GenericProblem,
                          domain_type::Symbol, state_type::Symbol)
    execute_def = quote
        function execute(domain::$domain_type, state::$state_type, term::Term)
            execute(domain, state, get_actions(domain)[term.name], term.args)
        end
        function execute(domain::$domain_type, state::$state_type, term::Term;
                         check::Bool=false)
            execute(domain, state, get_actions(domain)[term.name], term.args;
                    check=check)
        end
    end
    return execute_def
end

function generate_execute(domain::Domain, problem::GenericProblem,
                          domain_type::Symbol, state_type::Symbol,
                          action_name::Symbol, action_type::Symbol)
    action = get_actions(domain)[action_name]
    varmap = Dict(a => :(args[$i]) for (i, a) in enumerate(action.args))
    precond = generate_check_expr(domain, problem, action.precond, varmap)
    effect = generate_effect_expr(domain, problem, action.effect, varmap)
    execute_def = quote
        function execute(domain::$domain_type, prev_state::$state_type,
                         action::$action_type, args; check::Bool=false)
            if check && !($precond) error("Precondition not satisfied") end
            state = copy(prev_state)
            $effect
            return state
        end
    end
    return execute_def
end

function generate_transition(domain::Domain, problem::GenericProblem,
                             domain_type::Symbol, state_type::Symbol)
    transition_def = quote
        function transition(domain::$domain_type, state::$state_type,
                            term::Term)
            execute(domain, state, get_actions(domain)[term.name], term.args)
        end
        function transition(domain::$domain_type, state::$state_type,
                            term::Term; check::Bool=false)
            execute(domain, state, get_actions(domain)[term.name], term.args;
                    check=check)
        end
    end
    return transition_def
end

function compiled(domain::Domain, problem::GenericProblem)
    # Generate definitions
    domain_type, domain_typedef =
        generate_domain_type(domain, problem)
    state_type, state_typedef, state_method_defs =
        generate_state_type(domain, problem, domain_type)
    initstate_def =
        generate_initstate(domain, problem, domain_type, state_type)
    object_defs =
        generate_object_defs(domain, problem, domain_type, state_type)
    evaluate_def =
        generate_evaluate(domain, problem, domain_type, state_type)
    satisfy_def =
        generate_satisfy(domain, problem, domain_type, state_type)
    action_defs =
        generate_action_defs(domain, problem, domain_type, state_type)
    transition_def =
        generate_transition(domain, problem, domain_type, state_type)
    # Generate return expression
    return_expr =
        :($domain_type(), initstate($domain_type(), $(QuoteNode(problem))))
    # Evaluate definitions
    expr = Expr(:block,
        domain_typedef, state_typedef, state_method_defs, initstate_def,
        object_defs, evaluate_def, satisfy_def, action_defs, transition_def,
        return_expr)
    return eval(expr)
end
