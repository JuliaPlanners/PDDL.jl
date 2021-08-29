function generate_initstate(domain::Domain, state::State,
                            domain_type::Symbol, state_type::Symbol)
    convert_expr = domain isa AbstractedDomain ?
        :(val = IntervalAbs(val)) : quote end
    return quote
        function initstate(domain::$domain_type, problem::GenericProblem)
            state = $state_type()
            for term in problem.init
                if term.name == :(==)
                    term, val = term.args[1], term.args[2].name
                    $convert_expr
                else
                    val = true
                end
                set_fluent!(state, val, term)
            end
            return state
        end
    end
end
