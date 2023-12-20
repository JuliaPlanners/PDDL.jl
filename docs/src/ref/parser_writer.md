# Parser and Writer

PDDL.jl supports both parsing and writing of PDDL files and strings. In addition, the parser is designed to be extensible, allowing variants or extensions of PDDL to be easily supported.

## General Parsing

The `PDDL.Parser` submodule contains all functionality related to parsing PDDL strings and loading of PDDL files. To parse a string in PDDL, use the macro [`@pddl`](@ref) or the function [`parse_pddl`](@ref). Both of these return a list of parsed results if multiple strings are provided.

```@docs
@pddl
parse_pddl
```

Below we use [`@pddl`](@ref) to parse a sequence of predicates, and use [`parse_pddl`](@ref) to parse a PDDL axiom (a.k.a. derived predicate):

```julia-repl
julia> @pddl("(on a b)", "(on b c)")
2-element Vector{Compound}:
 on(a, b)
 on(b, c)
julia> parse_pddl("(:derived (handempty) (forall (?x) (not (holding ?x))))")
handempty <<= forall(object(X), not(holding(X)))
```

In addition, there exists a string macro `pddl"..."`, which is useful for parsing single string literals:

```julia-repl
julia> pddl"(on a b)"
on(a, b)
```

```@docs
@pddl_str
```

## Interpolation

The string macro `pddl"...` (as well as the [`@pddl`](@ref) macro) supports the interpolation of Julia variables using the `$` operator when parsing PDDL formulae. This makes it easier to construct predicates or expressions with a fixed structure but variable contents:

```julia
obj = Const(:a)
sym = :b
pddl"(on $obj $sym)"
# Parses to the same value as pddl"(on a b)"

fname = :on
pddl"($fname a b)"
# Also parses to pddl"(on a b)"

var = pddl"(?x)"
type = :block
pddl"(forall ($var - $type) (on-table $var))"
# Parses to pddl"(forall (?x - block) (on-table ?x))"
```

It is also possible to interpolate entire Julia expressions by surrounding the expression in curly braces (note that the expression itself must not contain any curly braces):

```julia
pddl"(= cost ${1 + 2})"     # Parses to pddl"(= cost 3)"
pddl"(= cost ${zero(Int)})" # Parses to pddl"(= cost 0)"
```

Interpolation is **not** supported when parsing larger PDDL constructs, such as actions, domains, and problems.

## Parsing Domains and Problems

To parse domains and problems specified as PDDL strings, use [`parse_domain`](@ref) and [`parse_problem`](@ref).

```@docs
parse_domain
parse_problem
```

To load domains or problems from a file, use [`load_domain`](@ref) and [`load_problem`](@ref).

```@docs
load_domain
load_problem
```

## Extending the Parser

The parser can be extended to handle new PDDL constructs using the following macros:

```@docs
PDDL.Parser.@add_top_level
PDDL.Parser.@add_header_field
PDDL.Parser.@add_body_field
```

## General Writing

The `PDDL.Writer` submodule contains all functionality related to writing PDDL strings and saving of PDDL files. To write a string in PDDL syntax, use the function [`write_pddl`](@ref).

```@docs
write_pddl
```

Below we use [`write_pddl`](@ref) to write out an [`Action`](@ref) from the [Blocksworld domain](https://github.com/JuliaPlanners/PlanningDomains.jl/blob/main/repositories/julia-planners/blocksworld/domain.pddl).

```julia-repl
julia> write_pddl(PDDL.get_action(domain, :stack)) |> print
(:action stack
 :parameters (?x ?y - block)
 :precondition (and (holding ?x) (clear ?y) (not (= ?x ?y)))
 :effect (and (not (holding ?x)) (not (clear ?y)) (clear ?x) (handempty) (on ?x ?y)))
```

## Writing Domains and Problems

To write domains and problem as PDDL strings, use [`write_domain`](@ref) and [`write_problem`](@ref).

```@docs
write_domain
write_problem
```

To save domains or problems as text files to a path, use [`save_domain`](@ref) and [`save_problem`](@ref).

```@docs
save_domain
save_problem
```
