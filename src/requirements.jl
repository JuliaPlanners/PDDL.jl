export DEFAULT_REQUIREMENTS

"Default PDDL requirements."
DEFAULT_REQUIREMENTS = Dict{Symbol,Bool}(
    Symbol("strips") => true,
    Symbol("typing") => false,
    Symbol("negative-preconditions") => true,
    Symbol("disjunctive-preconditions") => true,
    Symbol("equality") => true,
    Symbol("existential-preconditions") => false,
    Symbol("universal-preconditions") => false,
    Symbol("quantified-preconditions") => false,
    Symbol("conditional-effects") => true,
    Symbol("adl") => false
)
