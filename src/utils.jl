# domain[state => f] shorthand for evaluating `f` within a domain and state
Base.getindex(domain::Domain, statevar::Pair{<:State, <:Term}) =
    evaluate(domain, first(statevar), last(statevar))
Base.getindex(domain::Domain, statevar::Pair{<:State, Symbol}) =
    evaluate(domain, first(statevar), Const(last(statevar)))
Base.getindex(domain::Domain, statevar::Pair{<:State, String}) =
    evaluate(domain, first(statevar), Parser.parse_formula(last(statevar)))
