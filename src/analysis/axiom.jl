
"""
$(SIGNATURES)

Infer dependency structure between axioms.
"""
function infer_axiom_hierarchy(domain::Domain)
    parents = Dict{Symbol,Vector{Symbol}}()
    for (name, ax) in pairs(get_axioms(domain))
        body = length(ax.body) == 1 ? ax.body[1] : Compound(:and, ax.body)
        parents[name] = unique!([c.name for c in constituents(body, domain)])
    end
    children = Dict{Symbol,Vector{Symbol}}()
    for (name, ps) in parents
        for p in ps
            cs = get!(children, p, Symbol[])
            push!(cs, name)
        end
    end
    return parents, children
end

"""
$(SIGNATURES)

Substitute derived predicates in a term with their axiom bodies.
"""
function substitute_axioms(term::Term, domain::Domain; ignore=[])
    if term.name in ignore
        return term
    elseif is_derived(term, domain)
        # Substitute with axiom body, avoiding recursion
        axiom = Julog.freshen(get_axiom(domain, term.name))
        subst = unify(axiom.head, term)
        body = length(axiom.body) == 1 ?
            axiom.body[1] : Compound(:and, axiom.body)
        body = substitute(body, subst)
        body = substitute_axioms(body, domain, ignore=[term.name])
        return body
    elseif term isa Compound
        # Substitute each constituent term
        args = Term[substitute_axioms(a, domain, ignore=ignore)
                    for a in term.args]
        return Compound(term.name, args)
    else
        return term
    end
end
