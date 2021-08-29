function generate_satisfy(domain::Domain, state::State,
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
