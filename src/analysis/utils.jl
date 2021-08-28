"Check if term is a predicate."
is_pred(term::Term, domain::Domain) =
    term.name in keys(get_predicates(domain))

"Check if term is a numeric fluent (i.e. function)."
is_func(term::Term, domain::Domain) =
    term.name in keys(get_functions(domain))

"Check if term is a derived predicate"
is_derived(term::Term, domain::Domain) =
    term.name in keys(get_axioms(domain))

"Check if term is a domain fluent."
is_fluent(term::Term, domain::Domain) =
    is_pred(term, domain) || is_func(term, domain)

"Check if term is a type predicate."
is_type(term::Term, domain::Domain) =
    term.name in keys(get_types(domain))

"Check if term is a type predicate with subtypes."
has_subtypes(term::Term, domain::Domain) =
    !isempty(get_types(domain)[term.name])

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
    has_name(term, keys(get_axioms(domain)))

"Check if term contains a universal or existential quantifier."
has_quantifier(term::Term) =
    has_name(term, Set(Symbol[:forall, :exists]))

"Check if term contains a fluent name."
has_fluent(term::Term, domain::Domain) =
    has_pred(term, domain) || has_func(term, domain)
