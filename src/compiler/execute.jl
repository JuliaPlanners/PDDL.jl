function generate_execute(domain::Domain, state::State,
                          domain_type::Symbol, state_type::Symbol)
    execute_def = quote
        function execute(domain::$domain_type, state::$state_type, term::Term)
            execute(domain, state, get_action(domain, term.name), term.args)
        end
        function execute(domain::$domain_type, state::$state_type, term::Term;
                         check::Bool=false)
            execute(domain, state, get_action(domain, term.name), term.args;
                    check=check)
        end
        function execute!(domain::$domain_type, state::$state_type, term::Term)
            execute!(domain, state, get_action(domain, term.name), term.args)
        end
        function execute!(domain::$domain_type, state::$state_type, term::Term;
                          check::Bool=false)
            execute!(domain, state, get_action(domain, term.name), term.args;
                     check=check)
        end
    end
    return execute_def
end

function generate_execute(domain::Domain, state::State,
                          domain_type::Symbol, state_type::Symbol,
                          action_name::Symbol, action_type::Symbol)
    action = get_actions(domain)[action_name]
    varmap = Dict{Var,Any}(a => :(args[$i].name) for (i, a) in
                           enumerate(get_argvars(action)))
    # TODO: Fix mutating execute
    precond = generate_check_expr(domain, state, get_precond(action), varmap,
                                  :prev_state)
    effect = generate_effect_expr(domain, state, get_effect(action), varmap)
    effect! = generate_effect_expr(domain, state, get_effect(action), varmap,
                                   :prev_state)
    execute_def = quote
        function execute(domain::$domain_type, prev_state::$state_type,
                         action::$action_type, args; check::Bool=false)
            if check && !(@inbounds $precond)
                error("Precondition not satisfied")
            end
            state = copy(prev_state)
            @inbounds $effect
            return state
        end
        function execute!(domain::$domain_type, prev_state::$state_type,
                          action::$action_type, args; check::Bool=false)
            if check && !(@inbounds $precond)
                error("Precondition not satisfied")
            end
            @inbounds $effect!
            return prev_state
        end
    end
    return execute_def
end
