function generate_transition(domain::Domain, state::State,
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
