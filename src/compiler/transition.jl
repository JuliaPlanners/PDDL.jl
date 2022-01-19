function generate_transition(domain::Domain, state::State,
                             domain_type::Symbol, state_type::Symbol)
    transition_def = quote
        function transition(domain::$domain_type, state::$state_type,
                            term::Term; check::Bool=false)
            if term.name == get_name(PDDL.no_op) && isempty(term.args)
                execute(domain, state, PDDL.no_op, term.args; check=check)
            else
                execute(domain, state, get_action(domain, term.name), term.args;
                        check=check)
            end
        end
        function transition!(domain::$domain_type, state::$state_type,
                             term::Term; check::Bool=false)
            if term.name == get_name(PDDL.no_op) && isempty(term.args)
                execute(domain, state, PDDL.no_op, term.args; check=check)
            else
                execute(domain, state, get_action(domain, term.name), term.args;
                        check=check)
            end
        end
    end
    return transition_def
end
