function generate_action_defs(domain::Domain, state::State,
                              domain_type::Symbol, state_type::Symbol)
    available_def =
        generate_available(domain, state, domain_type, state_type)
    execute_def =
        generate_execute(domain, state, domain_type, state_type)
    all_action_defs = [available_def, execute_def]
    all_action_names = sortedkeys(get_actions(domain))
    all_action_types = Symbol[]
    for name in all_action_names
        action_defs =
            generate_action_defs(domain, state, domain_type, state_type, name)
        push!(all_action_types, action_defs[1])
        append!(all_action_defs, action_defs[2:end])
    end
    action_map = Expr(:tuple, (Expr(:(=), n, Expr(:call, act)) for (n, act)
                               in zip(all_action_names, all_action_types))...)
    get_actions_def = :(get_actions(::$domain_type) = $action_map)
    push!(all_action_defs, get_actions_def)
    return Expr(:block, all_action_defs...)
end

function generate_action_defs(domain::Domain, state::State,
                              domain_type::Symbol, state_type::Symbol,
                              action_name::Symbol)
    action_type = gensym("Compiled" * pddl_to_type_name(action_name) * "Action")
    action_typedef = :(struct $action_type <: CompiledAction end)
    groundargs_def =
        generate_groundargs(domain, state, domain_type, state_type,
                            action_name, action_type)
    available_def =
        generate_available(domain, state, domain_type, state_type,
                           action_name, action_type)
    execute_def =
        generate_execute(domain, state, domain_type, state_type,
                         action_name, action_type)
    method_defs =
        generate_action_methods(domain, state, domain_type, state_type,
                                action_name, action_type)
    return (action_type, action_typedef, method_defs,
            groundargs_def, available_def, execute_def)
end

function generate_action_methods(domain::Domain, state::State,
                              domain_type::Symbol, state_type::Symbol,
                              action_name::Symbol, action_type::Symbol)
    action = get_action(domain, action_name)
    get_name_def =
        :(get_name(::$action_type) = $(QuoteNode(get_name(action))))
    get_argvars_def =
        :(get_argvars(::$action_type) = $(QuoteNode(get_argvars(action))))
    get_argtypes_def =
        :(get_argtypes(::$action_type) = $(QuoteNode(get_argtypes(action))))
    get_precond_def =
        :(get_precond(::$action_type) = $(QuoteNode(get_precond(action))))
    get_effect_def =
        :(get_effect(::$action_type) = $(QuoteNode(get_effect(action))))
    method_defs = Expr(:block, get_name_def, get_argvars_def, get_argtypes_def,
                       get_precond_def, get_effect_def)
    return method_defs
end

function generate_groundargs(domain::Domain, state::State,
                             domain_type::Symbol, state_type::Symbol,
                             action_name::Symbol, action_type::Symbol)
    action = get_action(domain, action_name)
    argtypes = get_argtypes(action)
    if get_requirements(domain)[:typing]
        objs_exprs = [:(get_objects(state, $(QuoteNode(ty)))) for ty in argtypes]
    else
        objs_exprs = [:(get_objects(state)) for ty in argtypes]
    end
    iter_expr = :(Iterators.product($(objs_exprs...)))
    groundargs_def = quote
        function groundargs(domain::$domain_type, state::$state_type,
                            action::$action_type)
            return $iter_expr
        end
    end
    return groundargs_def
end
