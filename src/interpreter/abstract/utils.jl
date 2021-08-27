negate(term::Const) = Const(Symbol(:¬, term.name))
negate(term::Compound) = Compound(Symbol(:¬, term.name), term.args)

reify_negations(term::Compound) = term.name == :not ?
    negate(term.args[1]) : Compound(term.name, reify_negations.(term.args))
reify_negations(term::Var) =
    term
reify_negations(term::Const) =
    term

function get_negation_clauses(domain::Domain)
    return map(values(get_predicates(domain))) do sig
        pred = convert(Term, sig)
        Clause(negate(pred), [Compound(:not, [pred])])
    end
end
