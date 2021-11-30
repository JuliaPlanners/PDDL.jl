# Various term manipulation utilities

"""
    dequantify(term::Term, domain::Domain, state::State)

Replaces universally or existentially quantified expressions with their
corresponding conjuctions or disjunctions over the object types they quantify.
"""
function dequantify(term::Term, domain::Domain, state::State)
    if term.name in (:forall, :exists)
        typeconds, query = flatten_conjs(term.args[1]), term.args[2]
        query = dequantify(query, domain, state)
        ground_terms = [query]
        for cond in typeconds
            type, var = cond.name, cond.args[1]
            ground_terms = map(ground_terms) do gt
                return [substitute(gt, Subst(var => obj))
                        for obj in get_objects(domain, state, type)]
            end
            ground_terms = reduce(vcat, ground_terms)
        end
        op = term.name == :forall ? :and : :or
        return Compound(op, ground_terms)
    elseif term.name in (:and, :or, :imply, :not, :when)
        args = Term[dequantify(arg, domain, state) for arg in term.args]
        return Compound(term.name, args)
    else
        return term
    end
end

"""
    conds, effects = flatten_conditions(term::Term)

Flattens a (potentially nested) conditional effect `term` into a list of
condition lists (`conds`) and a list of effect lists (`effects`).
"""
function flatten_conditions(term::Term)
    if term.name == :when # Conditional case
        cond, effect = term.args[1], term.args[2]
        subconds, subeffects = flatten_conditions(effect)
        for sc in subconds prepend!(sc, flatten_conjs(cond)) end
        return subconds, subeffects
    elseif term.name == :and # Conjunctive case
        conds, effects = [Term[]], [Term[]]
        for effect in term.args
            subconds, subeffects = flatten_conditions(effect)
            for (c, e) in zip(subconds, subeffects)
                if isempty(c)
                    append!(effects[1], e)
                else
                    push!(conds, c)
                    push!(effects, e)
                end
            end
        end
        if isempty(effects[1])
            popfirst!(conds)
            popfirst!(effects)
        end
        return conds, effects
    else # Base case
        cond, effect = Term[], Term[term]
        return [cond], [effect]
    end
end

"""
    actions = flatten_conditions(action::GroundAction)

Flattens ground actions with conditional effects into multiple ground actions.
"""
function flatten_conditions(action::GroundAction)
    if (action.effect isa GenericDiff) return [action] end
    actions = GroundAction[]
    for (conds, diff) in zip(action.effect.conds, action.effect.diffs)
        preconds = [action.preconds; conds]
        push!(actions, GroundAction(action.name, action.term, preconds, diff))
    end
    return actions
end

"""
    clauses = to_cnf_clauses(term)

Convert a `term` to CNF and return a list of the clauses as terms. Clauses with
multiple literals have an `or` around them, but single-literal clauses do not.
"""
function to_cnf_clauses(term::Term)
    term = to_cnf(term)
    clauses = map!(c -> (length(c.args) == 1) ? c.args[1] : c,
                   similar(term.args), term.args)
    return clauses
end

"""
    clauses = to_dnf_clauses(term)

Convert a `term` to DNF and return a list of the clauses as terms. Clauses with
multiple literals have an `and` around them, but single-literal clauses do not.
"""
function to_dnf_clauses(term::Term)
    term = to_dnf(term)
    clauses = map!(c -> (length(c.args) == 1) ? c.args[1] : c,
                   similar(term.args), term.args)
    return clauses
end
