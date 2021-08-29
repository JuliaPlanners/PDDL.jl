function generate_execute(domain::Domain, state::State,
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

function generate_execute(domain::Domain, state::State,
                          domain_type::Symbol, state_type::Symbol,
                          action_name::Symbol, action_type::Symbol)
    action = get_actions(domain)[action_name]
    varmap = Dict(a => :(args[$i].name) for (i, a) in enumerate(action.args))
    precond = generate_check_expr(domain, state, action.precond, varmap)
    effect = generate_effect_expr(domain, state, action.effect, varmap)
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
