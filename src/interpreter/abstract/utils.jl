negate(term::Const) = Const(Symbol(:¬, term.name))
negate(term::Compound) = Compound(Symbol(:¬, term.name), term.args)

function reify_negations(term::Compound, domain::Domain)
    if term.name == :not && is_pred(term.args[1], domain)
        negate(term.args[1])
    else
        Compound(term.name, [reify_negations(a, domain) for a in term.args])
    end
end
reify_negations(term::Var, domain) =
    term
reify_negations(term::Const, domain) =
    term

function abstract_negations(term::Compound, domain::Domain)
    if term.name == :not && is_pred(term.args[1], domain)
        Compound(:or, Term[negate(term.args[1]), term])
    else
        Compound(term.name, [abstract_negations(a, domain) for a in term.args])
    end
end
abstract_negations(term::Var, domain) =
    term
abstract_negations(term::Const, domain) =
    term

function get_clauses(domain::AbstractedDomain)
    # Abstract negations in axioms
    axioms = map(collect(values(get_axioms(domain)))) do ax
        head = ax.head
        body = abstract_negations(to_nnf(Compound(:and, ax.body)), domain)
        return Clause(head, Term[body])
    end
    return [axioms; get_const_clauses(domain); get_type_clauses(domain)]
end
