"Abstract type representing differences between states."
abstract type Diff end

"""
    combine!(diff::Diff, ds::Diff...)

Combine state differences, modifying the first `Diff` in place.
"""
combine!(d::Diff) = d
combine!(d1::Diff, d2::Diff) = error("Not implemented.")
combine!(d1::Diff, d2::Diff, diffs::Diff...) =
    combine!(combine!(d1, d2), diffs...)

"""
    combine(diff::Diff, ds::Diff...)

Combine state differences, returning a fresh `Diff`.
"""
combine(diffs::Diff...) =
    combine!(empty(diffs[1]), diffs...)

"Convert a `Diff` to an equivalent `Term`."
as_term(diff::Diff) = error("Not implemented.")

"Return whether a `Diff` is redundant (i.e. does nothing)."
is_redundant(diff::Diff) = error("Not implemented.")

"Return an empty `Diff` of the same type as the input `Diff`."
Base.empty(diff::Diff) = error("Not implemented.")
