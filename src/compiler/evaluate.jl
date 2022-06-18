function generate_evaluate(domain::Domain, state::State,
                           domain_type::Symbol, state_type::Symbol)
    evaluate_def = quote
        function evaluate(domain::$domain_type, state::$state_type, term::Const)
            val = if !(term.name isa Symbol)
                term.name
            elseif hasfield($state_type, term.name)
                getfield(state, term.name)
            elseif is_global_func(term)
                function_def(term.name)()
            elseif is_derived(term, domain)
                get_fluent(state, term)
            else
                term.name
            end
            return val
        end
        function evaluate(domain::$domain_type, state::$state_type, term::Compound)
            func = is_global_func(term.name) ? function_def(term.name) : nothing
            val = if func !== nothing
                argvals = (evaluate(domain, state, arg) for arg in term.args)
                func(argvals...)
            else
                get_fluent(state, term)
            end
        end
    end
    return evaluate_def
end
