"Default PDDL requirements."
const DEFAULT_REQUIREMENTS = Dict{Symbol,Bool}(
    Symbol("strips") => true,
    Symbol("typing") => false,
    Symbol("negative-preconditions") => false,
    Symbol("disjunctive-preconditions") => false,
    Symbol("equality") => false,
    Symbol("existential-preconditions") => false,
    Symbol("universal-preconditions") => false,
    Symbol("quantified-preconditions") => false,
    Symbol("conditional-effects") => false,
    Symbol("adl") => false
)

const IMPLIED_REQUIREMENTS = Dict{Symbol,Vector{Symbol}}(
    Symbol("adl") => [
        Symbol("strips"),
        Symbol("typing"),
        Symbol("negative-preconditions"),
        Symbol("disjunctive-preconditions"),
        Symbol("equality"),
        Symbol("quantified-preconditions"),
        Symbol("conditional-effects")
    ],
    Symbol("quantified-preconditions") => [
        Symbol("existential-preconditions"),
        Symbol("universal-preconditions")
    ]
)
