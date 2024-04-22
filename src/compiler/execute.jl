function generate_execute(domain::Domain, state::State,
                          domain_type::Symbol, state_type::Symbol)
    execute_def = quote
        function execute(domain::$domain_type, state::$state_type, term::Term;
                         check::Bool=false)
            execute(domain, state, get_action(domain, term.name), term.args;
                    check=check)
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
    # TODO: Fix mutating execute to ensure parallel composition of effects
    precond = to_nnf(get_precond(action))
    precond = generate_check_expr(domain, state, precond, varmap, :prev_state)
    if domain isa AbstractedDomain
        precond = :($precond == true || $precond == both)
    end
    effect = generate_effect_expr(domain, state, get_effect(action), varmap)
    meffect = generate_effect_expr(domain, state, get_effect(action), varmap,
                                   :prev_state, :prev_state)
    execute_def = quote
        function execute(domain::$domain_type, prev_state::$state_type,
                         action::$action_type, args; check::Bool=false)
            if check && !(@inbounds $precond)
                action_str = Writer.write_formula(get_name(action), args)
                error("Could not execute $action_str: " *
                      "Precondition does not hold.")
              end
            state = copy(prev_state)
            @inbounds $effect
            return state
        end
        function execute!(domain::$domain_type, prev_state::$state_type,
                          action::$action_type, args; check::Bool=false)
            if check && !(@inbounds $precond)
                action_str = Writer.write_formula(get_name(action), args)
                error("Could not execute $action_str: " *
                      "Precondition does not hold.")
            end
            @inbounds $meffect
            return prev_state
        end
    end
    return execute_def
end
