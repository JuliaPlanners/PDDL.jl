function generate_available(domain::Domain, state::State,
                            domain_type::Symbol, state_type::Symbol,
                            action_name::Symbol, action_type::Symbol)
    action = get_actions(domain)[action_name]
    varmap = Dict{Var,Any}(a => :(args[$i].name) for (i, a) in
                           enumerate(get_argvars(action)))
    precond = to_nnf(get_precond(action))
    precond = generate_check_expr(domain, state, precond, varmap)
    if domain isa AbstractedDomain
        available_def = quote
            function available(domain::$domain_type, state::$state_type,
                               action::$action_type, args)
                precond = @inbounds $precond
                return precond == true || precond == both
            end
        end
    else
        available_def = quote
            function available(domain::$domain_type, state::$state_type,
                               action::$action_type, args)
                return @inbounds $precond
            end
        end
    end
    return available_def
end

function generate_available(domain::Domain, state::State,
                            domain_type::Symbol, state_type::Symbol)
    available_def = quote
        function available(domain::$domain_type, state::$state_type, term::Term)
            available(domain, state, get_actions(domain)[term.name], term.args)
        end
        function available(domain::$domain_type, state::$state_type)
            f = named_action -> begin
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
