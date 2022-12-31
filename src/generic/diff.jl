"""
    GenericDiff(add, del, ops)

Generic state difference represented as additions, deletions, and assignments.

# Fields

$(FIELDS)
"""
struct GenericDiff <: Diff
    "List of added `Term`s"
    add::Vector{Term}
    "List of deleted `Term`s"
    del::Vector{Term}
    "Dictionary mapping fluents to their assigned expressions."
    ops::Dict{Term,Term}
end

GenericDiff() = GenericDiff(Term[], Term[], Dict{Term,Any}())

function combine!(d1::GenericDiff, d2::GenericDiff)
    append!(d1.add, d2.add)
    append!(d1.del, d2.del)
    merge!(d1.ops, d2.ops)
    return d1
end

function as_term(diff::GenericDiff)
    add = diff.add
    del = [Compound(:not, [t]) for t in diff.del]
    ops = [Compound(:assign, [t, v]) for (t, v) in diff.ops]
    return Compound(:and, [add; del; ops])
end

is_redundant(diff::GenericDiff) =
    issetequal(diff.add, diff.del) && all(k == v for (k, v) in diff.ops)

Base.empty(diff::GenericDiff) = GenericDiff()

Base.isempty(diff::GenericDiff) =
    isempty(diff.add) && isempty(diff.del) && isempty(diff.ops)

"""
    ConditionalDiff(conds, diffs)

Conditional state difference, represented as paired conditions and sub-diffs.

# Fields

$(FIELDS)
"""
struct ConditionalDiff{D <: Diff} <: Diff
    "List of list of condition `Term`s for each sub-diff."
    conds::Vector{Vector{Term}}
    "List of sub-diffs."
    diffs::Vector{D}
end

ConditionalDiff{D}() where {D} = ConditionalDiff{D}([], Vector{D}())

function combine!(d1::ConditionalDiff{D}, d2::D) where {D}
    for (i, cs) in enumerate(d1.conds)
        if isempty(cs)
            combine!(d1.diffs[i], d2)
            return d1
        end
    end
    push!(d1.conds, Term[])
    push!(d1.diffs, d2)
    return d1
end

function combine!(d1::ConditionalDiff{D}, d2::ConditionalDiff{D}) where {D}
    append!(d1.conds, d2.conds)
    append!(d1.diffs, d2.diffs)
    return d1
end

function as_term(diff::ConditionalDiff)
    branches = map(zip(diff.conds, diff.diffs)) do (cs, d)
        effect = as_term(d)
        isempty(cs) && return effect
        cond = length(cs) == 1 ? cs[1] : Compound(:and, cs)
        return Compound(:when, [cond, effect])
    end
    return Compound(:and, branches)
end

is_redundant(diff::ConditionalDiff) = all(is_redundant.(diff.diffs))

Base.empty(diff::ConditionalDiff{D}) where {D} = ConditionalDiff{D}()

Base.isempty(diff::ConditionalDiff) =
    all(isempty.(diff.conds)) && all(isempty.(diff.diffs))
