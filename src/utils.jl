"Access the value of a fluent or fact in a state."
(::Colon)(domain::Domain, state::State, term::Term) =
    evaluate(domain, state, term)
(::Colon)(domain::Domain, state::State, term::String) =
    evaluate(domain, state, Parser.parse_formula(term))
(::Colon)(domain::Domain, state::State, term::Symbol) =
    evaluate(domain, state, Const(term))

"Check if `term` has a (sub-term with a) name in `names`."
has_name(term::Const, names) = term.name in names
has_name(term::Var, names) = false
has_name(term::Compound, names) =
    term.name in names || any(has_name(f, names) for f in term.args)

"Check if term contains a predicate name."
has_pred(term::Term, domain::Domain) =
    has_name(term, keys(get_predicates(domain)))

"Check if term contains the name of numeric fluent (i.e. function)."
has_func(term::Term, domain::Domain) =
    has_name(term, keys(get_functions(domain)))

"Check if term contains a derived predicate"
has_derived(term::Term, domain::Domain) =
    length(get_axioms(domain)) > 0 &&
    has_name(term, Set((ax.head.name for ax in get_axioms(domain))))

"Check if term contains a universal or existential quantifier."
has_quantifier(term::Term) =
    has_name(term, Set(Symbol[:forall, :exists]))
