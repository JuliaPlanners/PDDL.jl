function generate_satisfy(domain::Domain, state::State,
                          domain_type::Symbol, state_type::Symbol)
    satisfy_def = quote
        function check(::$domain_type, state::$state_type, term::Const)
            return state[term.name]
        end
        function check(domain::$domain_type, state::$state_type, term::Compound)
            val = if term.name == :and
                all(check(domain, state, a) for a in term.args)
            elseif term.name == :or
                any(check(domain, state, a) for a in term.args)
            elseif term.name == :imply
                !check(domain, state, term.args[1]) |
                check(domain, state, term.args[2])
            elseif term.name == :not
                !check(domain, state, term.args[1])
            elseif term.name in keys(comp_ops)
                comp_ops[term.name](evaluate(domain, state, term.args[1]),
                                    evaluate(domain, state, term.args[2]))
            elseif !is_ground(term)
                missing
            else
                evaluate(domain, state, term)
            end
            return val
        end
        function satisfy(domain::$domain_type, state::$state_type, term::Term)
            val = check(domain, state, term)
            val !== missing ? val : !isempty(satisfiers(domain, state, term))
        end
        function satisfy(domain::$domain_type, state::$state_type,
                         terms::AbstractVector{<:Term})
            val = all(check(domain, state, t) for t in terms)
            val !== missing ? val : !isempty(satisfiers(domain, state, terms))
        end
    end
    return satisfy_def
end

function generate_satisfy(domain::AbstractedDomain, state::State,
                          domain_type::Symbol, state_type::Symbol)
    satisfy_def = quote
        function check(::$domain_type, state::$state_type, term::Const)
            return state[term.name]
        end
        function check(domain::$domain_type, state::$state_type, term::Compound)
            val = if term.name == :and
                (&)((check(domain, state, a) for a in term.args)...)
            elseif term.name == :or
                (|)((check(domain, state, a) for a in term.args)...)
            elseif term.name == :imply
                !check(domain, state, term.args[1]) |
                check(domain, state, term.args[2])
            elseif term.name == :not
                !check(domain, state, term.args[1])
            elseif term.name in keys(comp_ops)
                comp_ops[term.name](evaluate(domain, state, term.args[1]),
                                    evaluate(domain, state, term.args[2]))
            elseif !is_ground(term)
                missing
            else
                evaluate(domain, state, term)
            end
            return val
        end
        function satisfy(domain::$domain_type, state::$state_type, term::Term)
            val = check(domain, state, term)
            return val !== missing ? (val == true || val == both) :
                !isempty(satisfiers(domain, state, term))
        end
        function satisfy(domain::$domain_type, state::$state_type,
                         terms::AbstractVector{<:Term})
            val = (&)((check(domain, state, t) for t in terms)...)
            return val !== missing ? (val == true || val == both) :
                !isempty(satisfiers(domain, state, terms))
        end
    end
    return satisfy_def
end

function satisfiers(domain::CompiledDomain, state::CompiledState,
                    terms::AbstractVector{<:Term})
    gen_state = GenericState(state)
    return satisfiers(get_source(domain), gen_state, terms)
end
