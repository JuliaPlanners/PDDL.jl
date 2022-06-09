# Utilities for converting axioms to ground actions

"Converts a domain axiom to an action."
function GenericAction(domain::Domain, axiom::Clause)
    term = axiom.head
    name = term.name
    args = term.args
    types = collect(get_predicate(domain, name).argtypes)
    precond = to_nnf(Compound(:and, axiom.body))
    effect = axiom.head
    return GenericAction(name, args, types, precond, effect)
end

"""
    groundaxioms(domain::Domain, state::State, axiom::Clause)

Converts a PDDL axiom to a set of ground actions.
"""
function groundaxioms(domain::Domain, state::State, axiom::Clause;
                      statics=infer_static_fluents(domain))
    action = GenericAction(domain, axiom)
    return groundactions(domain, state, action; statics=statics)
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
