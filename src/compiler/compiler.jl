abstract type CompiledDomain <: Domain end

abstract type CompiledState <: State end

abstract type CompiledAction <: Action end

function pddl_to_type_name(name)
    words = split(lowercase(string(name)), '-', keepempty=false)
    return join(uppercasefirst.(words))
end

function generate_domain_type(domain::GenericDomain, problem::GenericProblem)
     name = pddl_to_type_name(domain.name)
     domain_type = gensym("Compiled" * name * "Domain")
     domain_typedef = :(struct $domain_type <: CompiledDomain end)
     return (domain_type, domain_typedef)
end

function generate_state_type(domain::GenericDomain, problem::GenericProblem,
                             domain_type::Symbol)
    # Generate typedef
    state_fields = []
    for (_, pred) in sort(collect(domain.predicates), by=first)
        type = length(pred.args) == 0 ? Bool : BitArray{length(pred.args)}
        field = Expr(:(::), pred.name, QuoteNode(type))
        push!(state_fields, field)
    end
    for (_, fn) in sort(collect(domain.functions), by=first)
        type = length(fn.args) == 0 ? Float64 : Array{Float64, length(fn.args)}
        field = Expr(:(::), fn.name, QuoteNode(type))
        push!(state_fields, field)
    end
    state_type = gensym("Compiled" * pddl_to_type_name(domain.name) * "State")
    state_typesig = Expr(:(<:), state_type, QuoteNode(CompiledState))
    state_typedef = :(@auto_hash_equals $(Expr(:struct, true, state_typesig,
                                               Expr(:block, state_fields...))))
    # Generate constructor with no arguments
    n_objs = length(problem.objects)
    state_inits = []
    for (_, pred) in sort(collect(domain.predicates), by=first)
        if length(pred.args) == 0
            push!(state_inits, false)
        else
            dims = fill(n_objs, length(pred.args))
            push!(state_inits, :(falses($(dims...))))
        end
    end
    for (_, fn) in sort(collect(domain.functions), by=first)
        if length(fn.args) == 0
            push!(state_inits, 0.0)
        else
            dims = fill(n_objs, length(fn.args))
            push!(state_inits, :(zeros($(dims...))))
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

function generate_initstate(domain::GenericDomain, problem::GenericProblem,
                            domain_type::Symbol, state_type::Symbol)
    return quote
        function initstate(::$domain_type, problem::GenericProblem)
            state = $state_type()
            for term in problem.init
                if term.name == :(==)
                    term, val = term.args[1], term.args[2].name
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

function generate_object_defs(domain::GenericDomain, problem::GenericProblem,
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

function generate_get_expr(domain::GenericDomain, problem::GenericProblem,
                           term::Const, varmap=Dict{Var,Any}())
    return :(state.$(term.name))
end

function generate_get_expr(domain::GenericDomain, problem::GenericProblem,
                           term::Var, varmap=Dict{Var,Any}())
    return :($(varmap[term]).name)
end

function generate_get_expr(domain::GenericDomain, problem::GenericProblem,
                           term::Compound, varmap=Dict{Var,Any}())
    object_ids = (; ((o.name, i) for (i, o) in enumerate(problem.objects))...)
    indices = (a isa Var ? :(objectindex(state, $(varmap[a]).name)) :
               object_ids[a.name] for a in term.args)
    return :(state.$(term.name)[$(indices...)])
end

function generate_set_expr(domain::GenericDomain, problem::GenericProblem,
                           term::Const, val, varmap=Dict{Var,Any}())
    return :(state.$(term.name) = $val)
end

function generate_set_expr(domain::GenericDomain, problem::GenericProblem,
                           term::Compound, val, varmap=Dict{Var,Any}())
    object_ids = (; ((o.name, i) for (i, o) in enumerate(problem.objects))...)
    indices = (a isa Var ? :(objectindex(state, $(varmap[a]).name)) :
               object_ids[a.name] for a in term.args)
    return :(state.$(term.name)[$(indices...)] = $val)
end

function generate_check_expr(domain::GenericDomain, problem::GenericProblem,
                             term::Term, varmap=Dict{Var,Any}())
    if (term.name in union(keys(domain.predicates), keys(domain.functions)) ||
        term isa Var)
        return generate_get_expr(domain, problem, term, varmap)
    end
    subexprs = [generate_check_expr(domain, problem, a, varmap)
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
        Expr(:call, term.name, subexprs...)
    else
        error("Unrecognized predicate or operator $(term.name).")
    end
    return expr
end

function generate_effect_expr(domain::GenericDomain, problem::GenericProblem,
                              term::Term, varmap=Dict{Var,Any}())
    expr = if term.name == :and
        subexprs = [generate_effect_expr(domain, problem, a, varmap)
                    for a in term.args]
        Expr(:block, subexprs...)
    elseif term.name == :not
        @assert length(term.args) == 1 "not takes one argument"
        term = term.args[1]
        @assert term.name in keys(domain.predicates) "unrecognized predicate"
        generate_set_expr(domain, problem, term, false, varmap)
    elseif term.name in keys(domain.predicates)
        generate_set_expr(domain, problem, term, true, varmap)
    else
        error("Unrecognized predicate or operator $(term.name).")
    end
    return expr
end

function generate_evaluate(domain::GenericDomain, problem::GenericProblem,
                           domain_type::Symbol, state_type::Symbol)
    evaluate_def = quote
        function evaluate(domain::$domain_type, state::$state_type, term::Const)
            return term.name in fieldnames($state_type) ?
                getfield(state, term.name) : term.name
        end
        function evaluate(::$domain_type, state::$state_type, term::Compound)
            indices = (objectindex(state, a.name) for a in term.args)
            return getfield(state, term.name)[indices...]
        end
    end
    return evaluate_def
end

function generate_satisfy(domain::GenericDomain, problem::GenericProblem,
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

function generate_action_defs(domain::GenericDomain, problem::GenericProblem,
                              domain_type::Symbol, state_type::Symbol)
    available_def =
        generate_available(domain, problem, domain_type, state_type)
    execute_def =
        generate_execute(domain, problem, domain_type, state_type)
    all_action_defs = [available_def, execute_def]
    all_action_names = sort(collect(keys(domain.actions)))
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

function generate_action_defs(domain::GenericDomain, problem::GenericProblem,
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

function generate_groundargs(domain::GenericDomain, problem::GenericProblem,
                             domain_type::Symbol, state_type::Symbol,
                             action_name::Symbol, action_type::Symbol)
    action = domain.actions[action_name]
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

function generate_available(domain::GenericDomain, problem::GenericProblem,
                            domain_type::Symbol, state_type::Symbol,
                            action_name::Symbol, action_type::Symbol)
    action = domain.actions[action_name]
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

function generate_available(domain::GenericDomain, problem::GenericProblem,
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

function generate_execute(domain::GenericDomain, problem::GenericProblem,
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

function generate_execute(domain::GenericDomain, problem::GenericProblem,
                          domain_type::Symbol, state_type::Symbol,
                          action_name::Symbol, action_type::Symbol)
    action = domain.actions[action_name]
    varmap = Dict(a => :(args[$i]) for (i, a) in enumerate(action.args))
    precond = generate_check_expr(domain, problem, action.precond, varmap)
    effect = generate_effect_expr(domain, problem, action.effect, varmap)
    execute_def = quote
        function execute(domain::$domain_type, state::$state_type,
                         action::$action_type, args; check::Bool=false)
            if check && !($precond) error("Precondition not satisfied") end
            state = copy(state)
            $effect
            return state
        end
    end
    return execute_def
end

function generate_transition(domain::GenericDomain, problem::GenericProblem,
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

function compile(domain::GenericDomain, problem::GenericProblem)
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
