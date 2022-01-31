"Check if term is a predicate."
is_pred(term::Term, domain::Domain) =
    term.name in keys(get_predicates(domain))

"Check if term is a non-boolean fluent (i.e. function)."
is_func(term::Term, domain::Domain) =
    term.name in keys(get_functions(domain))

"Check if term is an external function attached to a domain."
is_attached_func(term::Term, domain::Domain) =
    term.name in keys(get_funcdefs(domain))

"Check if term is an external function (attached or global)."
is_external_func(term::Term, domain::Domain) =
    is_global_func(term) || is_attached_func(term, domain)

"Check if term is a derived predicate"
is_derived(term::Term, domain::Domain) =
    term.name in keys(get_axioms(domain))

"Check if term is a domain fluent."
is_fluent(term::Term, domain::Domain) =
    is_pred(term, domain) || is_func(term, domain)

"Check if term is a universal or existential quantifier."
is_quantifier(term::Term) =
    term.name == :forall || term.name == :exists

"Check if term is a global predicate (comparison, equality, etc.)."
is_global_pred(term::Term) =
    term.name in keys(GLOBAL_PREDICATES)

"Check if term is a global function, including global predicates."
is_global_func(term::Term) =
    term.name in keys(GLOBAL_FUNCTIONS)

"Check if term is a logical operator."
is_logical_op(term::Term) =
    term.name in (:and, :or, :not, :imply, :exists, :forall)

"Check if term is a type predicate."
is_type(term::Term, domain::Domain) =
    term.name in get_types(domain)

"Check if term is a type predicate with subtypes."
has_subtypes(term::Term, domain::Domain) =
    !isempty(get_subtypes(domain, term.name))

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

"Check if term contains the name of global function."
has_global_func(term::Term) =
    has_name(term, keys(GLOBAL_PREDICATES))

"Check if contains a logical operator."
has_logical_op(term::Term) =
    has_name(term, Set([:and, :or, :not, :imply, :exists, :forall]))

"Check if term contains a derived predicate"
has_derived(term::Term, domain::Domain) =
    has_name(term, keys(get_axioms(domain)))

"Check if term contains a universal or existential quantifier."
has_quantifier(term::Term) =
    has_name(term, Set([:forall, :exists]))

"Check if term contains a negated literal."
has_negation(term::Term) =
    has_name(term, (:not,))

"Check if term contains a fluent name."
has_fluent(term::Term, domain::Domain) =
    has_pred(term, domain) || has_func(term, domain)

"Returns list of constituent fluents."
constituents(term::Const, domain::Domain) =
    is_fluent(term, domain) ? [term] : []
constituents(term::Var, domain::Domain) =
    false
constituents(term::Compound, domain) = is_fluent(term, domain) ?
    Term[term] : reduce(vcat, (constituents(a, domain) for a in term.args))
