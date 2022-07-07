# Various term manipulation utilities

"Returns an iterator over all ground arguments of a `fluent`."
function groundargs(domain::Domain, state::State, fluent::Symbol)
    if get_requirements(domain)[:typing]
        argtypes = get_fluent(domain, fluent).argtypes
        obj_iters = (get_objects(domain, state, ty) for ty in argtypes)
    else
        n = arity(get_fluent(domain, fluent))
        obj_iters = (get_objects(state) for i in 1:n)
    end
    return Iterators.product(obj_iters...)
end

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

"Checks if a term or list of terms is in conjunctive normal form."
is_cnf(term::Term) =
    term.name == :and && is_cnf(term.args)
is_cnf(terms::AbstractVector{<:Term}) =
    all(is_cnf_clause(t) for t in terms)

"Checks if a term or list of terms is a CNF clause."
is_cnf_clause(term::Term) =
    (term.name == :or && is_cnf_clause(term.args)) || is_literal(term)
is_cnf_clause(terms::AbstractVector{<:Term}) =
    all(is_literal(t) for t in terms)

"Checks if a term or list of terms is in disjunctive normal form."
is_dnf(term::Term) =
    term.name == :or && is_dnf(term.args)
is_dnf(terms::AbstractVector{<:Term}) =
    all(is_dnf_clause(t) for t in terms)

"Checks if a term or list of terms is a CNF clause."
is_dnf_clause(term::Term) =
    (term.name == :and && is_dnf_clause(term.args)) || is_literal(term)
is_dnf_clause(terms::AbstractVector{<:Term}) =
    all(is_literal(t) for t in terms)

"""
    clauses = to_cnf_clauses(term)

Convert a `term` to CNF and return a list of the clauses as terms. Clauses with
multiple literals have an `or` around them, but single-literal clauses do not.
"""
function to_cnf_clauses(term::Term)
    term = to_cnf(term)
    clauses = map!(similar(term.args), term.args) do c
        (length(c.args) == 1) ? c.args[1] : Compound(c.name, unique!(c.args))
    end
    filter!(clauses) do c # Filter out clauses with conflicting literals
        c.name != :or && return true
        negated = [term.args[1] for term in c.args if term.name == :not]
        return !any(term in c.args for term in negated)
    end
    return clauses
end
to_cnf_clauses(terms::AbstractVector{<:Term}) =
    isempty(terms) ? Term[] : reduce(vcat, (to_cnf_clauses(t) for t in terms))

"""
    clauses = to_dnf_clauses(term)

Convert a `term` to DNF and return a list of the clauses as terms. Clauses with
multiple literals have an `and` around them, but single-literal clauses do not.
"""
function to_dnf_clauses(term::Term)
    term = to_dnf(term)
    clauses = map!(similar(term.args), term.args) do c
        (length(c.args) == 1) ? c.args[1] : Compound(c.name, unique!(c.args))
    end
    filter!(clauses) do c # Filter out clauses with conflicting literals
        c.name != :and && return true
        negated = [term.args[1] for term in c.args if term.name == :not]
        return !any(term in c.args for term in negated)
    end
    return clauses
end
to_dnf_clauses(terms::AbstractVector{<:Term}) =
    isempty(terms) ? Term[] : reduce(vcat, (to_dnf_clauses(t) for t in terms))
