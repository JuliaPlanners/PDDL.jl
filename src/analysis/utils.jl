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

"Check if term is a (non-external) domain fluent."
is_fluent(term::Term, domain::Domain) =
    is_pred(term, domain) || is_func(term, domain) && !is_attached_func(term, domain)

"Check if term is a negation of another term."
is_negation(term::Term) =
    term.name == :not

"Check if term is a universal or existential quantifier."
is_quantifier(term::Term) =
    term.name == :forall || term.name == :exists

"Check if term is a global predicate (comparison, equality, etc.)."
is_global_pred(term::Term) =
    term.name isa Symbol && is_global_pred(term.name)

"Check if term is a global function, including global predicates."
is_global_func(term::Term) =
    term.name isa Symbol && is_global_func(term.name)

"Check if term is a logical operator."
is_logical_op(term::Term) =
    term.name in (:and, :or, :not, :imply, :exists, :forall)

"Check if term is a literal (an atomic formula or its negation.)"
is_literal(term::Term) =
    !is_logical_op(term) || term.name == :not && !is_logical_op(term)

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

"Check if term contains the name of global predicate."
has_global_pred(term::Term) =
    has_name(term, global_predicate_names())

"Check if term contains the name of numeric fluent (i.e. function)."
has_func(term::Term, domain::Domain) =
    has_name(term, keys(get_functions(domain)))

"Check if term contains the name of a global function."
has_global_func(term::Term) =
    has_name(term, global_function_names())

"Check if contains a logical operator."
has_logical_op(term::Term) =
    has_name(term, (:and, :or, :not, :imply, :exists, :forall))

"Check if term contains a derived predicate"
has_derived(term::Term, domain::Domain) =
    has_name(term, keys(get_axioms(domain)))

"Check if term contains a universal or existential quantifier."
has_quantifier(term::Term) =
    has_name(term, (:forall, :exists))

"Check if term contains a negated literal."
has_negation(term::Term) =
    has_name(term, (:not,))

"Check if term contains a fluent name."
has_fluent(term::Term, domain::Domain) =
    has_pred(term, domain) || has_func(term, domain)

"Returns list of constituent fluents."
constituents(term::Term, domain::Domain) =
    constituents!(Term[], term, domain)
constituents!(fluents, term::Const, domain::Domain) =
    is_fluent(term, domain) ? push!(fluents, term) : fluents
constituents!(fluents, term::Var, domain::Domain) =
    fluents
function constituents!(fluents, term::Compound, domain)
    if is_fluent(term, domain)
        push!(fluents, term)
    else
        for arg in term.args
            constituents!(fluents, arg, domain)
        end
    end
    return fluents
end
