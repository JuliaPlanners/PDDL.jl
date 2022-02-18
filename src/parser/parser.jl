module Parser

export parse_domain, parse_problem, parse_pddl, @pddl, @pddl_str
export load_domain, load_problem

using ParserCombinator, Julog
using ..PDDL: Signature, GenericDomain, GenericProblem, GenericAction
using ..PDDL: DEFAULT_REQUIREMENTS, IMPLIED_REQUIREMENTS

"PDDL keyword."
struct Keyword
    name::Symbol
end
Base.show(io::IO, kw::Keyword) = print(io, "KW:", kw.name)

"Parsers for top-level PDDL descirptions."
const top_level_parsers = Dict{Symbol,Function}()

"Header field parsers for top-level PDDL descriptions (domains, problems, etc.)."
const head_field_parsers = Dict{Symbol,Dict{Symbol,Function}}(
    :domain => Dict{Symbol,Function}(),
    :problem => Dict{Symbol,Function}()
)

"Body field parsers for top-level PDDL descriptions (domains, problems, etc.)."
const body_field_parsers = Dict{Symbol,Dict{Symbol,Function}}(
    :domain => Dict{Symbol,Function}(),
    :problem => Dict{Symbol,Function}()
)

# Utility functions
include("utils.jl")
# Lisp-style grammar for PDDL
include("grammar.jl")
# Parsers for PDDL formulas
include("formulas.jl")
# Parser for top-level PDDL descriptions
include("descriptions.jl")
# Parsers for PDDL domains
include("domain.jl")
# Parsers for PDDL problems
include("problem.jl")

"Parse to PDDL structure based on initial keyword."
function parse_pddl(expr::Vector)
    if isa(expr[1], Keyword)
        kw = expr[1].name
        for desc in keys(top_level_parsers)
            if kw in keys(head_field_parsers[desc])
                return head_field_parsers[desc][kw](expr)
            elseif kw in keys(body_field_parsers[desc])
                return body_field_parsers[desc][kw](expr)
            end
        end
        error("Keyword $kw not recognized.")
    elseif expr[1] == :define
        kw = expr[2][1]
        return top_level_parsers[kw](expr)
    else
        return parse_formula(expr)
    end
end
parse_pddl(sym::Symbol) = parse_formula(sym)
parse_pddl(str::AbstractString) = parse_pddl(parse_string(str))
parse_pddl(strs::AbstractString...) = [parse_pddl(parse_string(s)) for s in strs]

"Parse string(s) to PDDL construct."
macro pddl(str::AbstractString)
    return parse_pddl(str)
end

macro pddl(strs::AbstractString...)
    return collect(parse_pddl.(strs))
end

"Parse string to PDDL construct."
macro pddl_str(str::AbstractString)
    return parse_pddl(str)
end

"""
    load_domain(path::AbstractString)
    load_domain(io::IO)

Load PDDL domain from specified path or IO object.
"""
function load_domain(io::IO)
    str = read(io, String)
    return parse_domain(str)
end
load_domain(path::AbstractString) = open(io->load_domain(io), path)

"""
    load_problem(path::AbstractString)
    load_problem(io::IO)

Load PDDL problem from specified path or IO object.
"""
function load_problem(io::IO)
    str = read(io, String)
    return parse_problem(str)
end
load_problem(path::AbstractString) = open(io->load_problem(io), path)

end
