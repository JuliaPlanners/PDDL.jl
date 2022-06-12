# Utilities for converting axioms to ground actions

"Converts a domain axiom to an action."
function GenericAction(domain::Domain, axiom::Clause; negated::Bool=false)
    term = axiom.head
    name = term.name
    args = term.args
    types = collect(get_predicate(domain, name).argtypes)
    precond = Compound(:and, axiom.body)
    effect = axiom.head
    if negated
        name = Symbol(:not, :-, name)
        precond = Compound(:not, Term[precond])
        effect = Compound(:not, Term[effect])
    end
    return GenericAction(name, args, types, to_nnf(precond), effect)
end

"""
    groundaxioms(domain::Domain, state::State, axiom::Clause)

Converts a PDDL axiom to a set of ground actions.
"""
function groundaxioms(domain::Domain, state::State, axiom::Clause;
                      statics=infer_static_fluents(domain))
    action = GenericAction(domain, axiom)
    neg_action = GenericAction(domain, axiom; negated=true)
    return [groundactions(domain, state, action; statics=statics);
            groundactions(domain, state, neg_action; statics=statics)]
end

"""
    groundaxioms(domain::Domain, state::State)

Convert all axioms into ground actions for a `domain` and initial `state`.
"""
function groundaxioms(domain::Domain, state::State)
    statics = infer_static_fluents(domain)
    iters = (groundaxioms(domain, state, axiom; statics=statics)
             for axiom in values(get_axioms(domain)))
    return collect(Iterators.flatten(iters))
end
