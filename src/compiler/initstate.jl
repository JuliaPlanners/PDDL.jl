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
                if term isa Const
                    setproperty!(state, term.name, val)
                else
                    argtypes = get_fluent(domain, term.name).argtypes
                    idxs = (objectindex(state, ty, a.name)
                            for (a, ty) in zip(term.args, argtypes))
                    getproperty(state, term.name)[idxs...] = val
                end
            end
            return state
        end
    end
end
