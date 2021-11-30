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

"Returns an iterator over all ground arguments of an `action`."
function groundargs(domain::Domain, state::State, action::Action)
    iters = (get_objects(domain, state, ty) for ty in get_argtypes(action))
    return Iterators.product(iters...)
end

"""
    groundactions(domain::Domain, state::State, action::GenericAction)

Returns ground actions for a lifted `action` in a `domain` and initial `state`.
"""
function groundactions(domain::Domain, state::State, action::GenericAction)
    ground_acts = GroundAction[]
    act_name = get_name(action)
    act_vars = get_argvars(action)
    statics = infer_static_fluents(domain)
    # Dequantify and flatten preconditions and effects
    _precond = dequantify(get_precond(action), domain, state)
    _effect = dequantify(get_effect(action), domain, state)
    _conds, _effects = flatten_conditions(_effect)
    for args in groundargs(domain, state, action)
        subst = Subst(var => val for (var, val) in zip(act_vars, args))
        term = Compound(act_name, collect(args))
        # Substitute and simplify precondition
        precond = substitute(_precond, subst)
        precond = simplify_statics(precond, domain, state, statics)
        precond.name == false && continue # Skip if never satisfiable
        preconds = to_cnf_clauses(precond)
        # Simplify conditions of conditional effects
        conds = map(_conds) do cs
            isempty(cs) && return cs
            cond = substitute(Compound(:and, cs), subst)
            cond = simplify_statics(cond, domain, state, statics)
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
