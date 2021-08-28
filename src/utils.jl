"Access the value of a fluent or fact in a state."
(::Colon)(domain::Domain, state::State, term::Term) =
    evaluate(domain, state, term)
(::Colon)(domain::Domain, state::State, term::String) =
    evaluate(domain, state, Parser.parse_formula(term))
(::Colon)(domain::Domain, state::State, term::Symbol) =
    evaluate(domain, state, Const(term))
