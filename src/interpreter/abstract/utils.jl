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

function get_negation_clauses(domain::Domain)
    return map(values(get_predicates(domain))) do sig
        pred = convert(Term, sig)
        Clause(negate(pred), [Compound(:not, [pred])])
    end
end
