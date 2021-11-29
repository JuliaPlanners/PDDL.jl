struct GroundBasicDiff
    additions::Vector{Term}
    deletions::Vector{Term}
    assignments::Dict{Term,Term}
end

function GroundBasicDiff(effects::AbstractVector{<:Term})
    additions, deletions, assignments = Term[], Term[], Dict{Term,Term}()
    for e in effects
        if e.name == :assign || e.name in keys(GLOBAL_MODIFIERS)
            assignments[e.args[1]] = e
        elseif e.name == :not
            push!(deletions, e.args[1])
        else
            push!(additions, e)
        end
    end
    return GroundBasicDiff(additions, deletions, assignments)
end

is_redundant(diff::GroundBasicDiff) =
    isempty(diff.assignments) && issetequal(diff.additions, diff.deletions)

struct GroundCondDiff
    conds::Vector{Vector{Term}}
    diffs::Vector{GroundBasicDiff}
end

const GroundDiff = Union{GroundBasicDiff,GroundCondDiff}

struct GroundAction <: Action
    name::Symbol
    term::Compound
    preconds::Vector{Term}
    effect::GroundDiff
end

function groundargs(domain::Domain, state::State, action::GenericAction)
    iters = (get_objects(domain, state, ty) for ty in get_argtypes(action))
    return Iterators.product(iters...)
end

function groundactions(domain::Domain, state::State, action::GenericAction)
    ground_acts = GroundAction[]
    act_name = get_name(action)
    act_vars = get_argvars(action)
    statics = infer_static_fluents(domain)
    # Dequantify and flatten preconditions and effects
    _precond = dequantify(domain, state, get_precond(action))
    _effect = dequantify(domain, state, get_effect(action))
    _conds, _effects = flatten_conditions(_effect)
    for args in groundargs(domain, state, action)
        subst = Subst(var => val for (var, val) in zip(act_vars, args))
        term = Compound(act_name, collect(args))
        # Substitute and simplify precondition
        precond = substitute(_precond, subst)
        precond = static_simplify(domain, state, precond, statics)
        precond.name == false && continue # Skip if never satisfiable
        preconds = to_cnf_clauses(precond)
        # Simplify conditions of conditional effects
        conds = map(_conds) do cs
            isempty(cs) && return cs
            cond = substitute(Compound(:and, cs), subst)
            cond = static_simplify(domain, state, cond, statics)
            return to_cnf_clauses(cond)
        end
        # Construct diffs from conditional effect terms
        diffs = map(_effects) do effs
            effs = [substitute(e, subst) for e in effs]
            return GroundBasicDiff(effs)
        end
        # Construct conditional diff if necessary
        if length(diffs) > 1
            effect = GroundCondDiff(conds, diffs)
        else
            is_redundant(diffs[1]) && continue
            effect = diffs[1]
            append!(preconds, conds[1])
        end
        # Construct ground action
        act = GroundAction(act_name, term, preconds, effect)
        push!(ground_acts, act)
    end
    return ground_acts
end

function dequantify(domain::Domain, state::State, term::Term)
    if term.name in (:forall, :exists)
        typeconds, query = flatten_conjs(term.args[1]), term.args[2]
        query = dequantify(domain, state, query)
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
        args = Term[dequantify(domain, state, arg) for arg in term.args]
        return Compound(term.name, args)
    else
        return term
    end
end

function static_simplify(domain::Domain, state::State, term::Term,
                         statics=nothing)
    if statics === nothing statics = infer_static_fluents(domain) end
    # Simplify predicates if they are static and ground
    if is_static(term, domain, statics) && is_ground(term)
        return Const(evaluate(domain, state, term))
    elseif !(term.name in (:and, :or, :imply, :not))
        return term
    end
    # Simplify logical compounds
    args = Term[static_simplify(domain, state, a, statics) for a in term.args]
    if term.name == :and
        true_idxs = Int[]
        for (i, a) in enumerate(args)
            a.name == false && return Const(false)
            a.name == true && push!(true_idxs, i)
        end
        length(true_idxs) == length(args) && return Const(true)
        deleteat!(args, true_idxs)
        return length(args) == 1 ? args[1] : Compound(:and, args)
    elseif term.name == :or
        false_idxs = Int[]
        for (i, a) in enumerate(args)
            a.name == true && return Const(true)
            a.name == false && push!(false_idxs, i)
        end
        length(false_idxs) == length(args) && return Const(false)
        deleteat!(args, false_idxs)
        return length(args) == 1 ? args[1] : Compound(:or, args)
    elseif term.name == :imply
        cond, query = args
        cond.name == true && return query
        cond.name == false && return Const(true)
        return Compound(:imply, args)
    elseif term.name == :not
        val = args[1].name
        return val isa Bool ? Const(!val) : Compound(:not, args)
    else
        error("Unrecognized logical operator: $(term.name)")
    end
end

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

function to_cnf_clauses(term::Term)
    term = to_cnf(term)
    clauses = map(term.args) do c
        length(c.args) == 1 ? c.args[1] : c
    end
    return clauses
end

to_cnf_clauses(terms) = reduce(vcat, to_cnf_clauses.(terms))
