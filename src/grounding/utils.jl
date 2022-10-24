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
function dequantify(term::Term, domain::Domain, state::State,
                    statics=infer_static_fluents(domain))
    if is_quantifier(term)
        conds, query = flatten_conjs(term.args[1]), term.args[2]
        query = dequantify(query, domain, state, statics)
        # Dequantify by type if no static fluents
        if statics === nothing || isempty(statics)
            return dequantify_by_type(term.name, conds, query, domain, state)
        else # Dequantify by static conditions otherwise
            return dequantify_by_stat_conds(term.name, conds, query,
                                            domain, state, statics)
        end
    elseif term.name in (:and, :or, :imply, :not, :when)
        args = Term[dequantify(arg, domain, state, statics)
                    for arg in term.args]
        return Compound(term.name, args)
    else
        return term
    end
end

"Dequantifies a quantified expression by the types it is quantified over."
function dequantify_by_type(
    name::Symbol, typeconds::Vector{Term}, query::Term,
    domain::Domain, state::State
)
    # Accumulate list of ground terms
    stack = Term[]
    subterms = Term[query]
    for cond in typeconds
        # Swap array references
        stack, subterms = subterms, stack
        # Substitute all objects of each type
        type, var = cond.name, cond.args[1]
        objects = get_objects(domain, state, type)
        while !isempty(stack)
            term = pop!(stack)
            for obj in objects
                push!(subterms, substitute(term, Subst(var => obj)))
            end
        end
    end
    # Return conjunction / disjunction of ground terms
    if name == :forall
        return isempty(subterms) ? Const(true) : Compound(:and, subterms)
    else # name == :exists
        return isempty(subterms) ? Const(false) : Compound(:or, subterms)
    end
end

"Dequantifies a quantified expression via static satisfaction (where useful)."
function dequantify_by_stat_conds(
    name::Symbol, conds::Vector{Term}, query::Term,
    domain::Domain, state::State, statics::Vector{Symbol}
)
    vars = Var[c.args[1] for c in conds]
    types = Symbol[c.name for c in conds]
    # Determine conditions that potentially restrict dequantification
    if name == :forall
        extra_conds = query.name in (:when, :imply) ? query.args[1] : Term[]
    else # name == :exists
        extra_conds = query
    end
    # Add static conditions
    for c in flatten_conjs(extra_conds)
        c.name in statics || continue
        push!(conds, c)
    end
    # Default to dequantifying by types if no static conditions were added
    if length(conds) == length(vars)
        return dequantify_by_type(name, conds, query, domain, state)
    end
    # Check if static conditions actually restrict the number of groundings
    substs = satisfiers(domain, state, conds)
    if prod(get_object_count(domain, state, ty) for ty in types) < length(substs)
        conds = resize!(conds, length(vars))
        return dequantify_by_type(name, conds, query, domain, state)
    end
    # Accumulate list of ground terms
    subterms = Term[]
    for s in substs
        length(s) > length(vars) && filter!(p -> first(p) in vars, s)
        push!(subterms, substitute(query, s))
    end
    # Return conjunction / disjunction of ground terms
    if name == :forall
        return isempty(subterms) ? Const(true) : Compound(:and, subterms)
    else # name == :exists
        return isempty(subterms) ? Const(false) : Compound(:or, subterms)
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
    elseif term.name == true  # Empty effects (due to simplification)
        cond, effect = Term[], Term[]
        return [cond], [effect]
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
