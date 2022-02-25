module Parser

export parse_domain, parse_problem, parse_pddl, @pddl, @pddl_str
export load_domain, load_problem

using ParserCombinator, Julog, ValSplit
using ..PDDL: Signature, GenericDomain, GenericProblem, GenericAction
using ..PDDL: DEFAULT_REQUIREMENTS, IMPLIED_REQUIREMENTS

"PDDL keyword."
struct Keyword
    name::Symbol
end
Base.show(io::IO, kw::Keyword) = print(io, "KW:", kw.name)

"Parse top level description to a PDDL.jl data structure."
@valsplit parse_top_level(Val(name::Symbol), expr) =
    error("Unrecognized description: :$name")

"Returns whether `name` is associated with a top-level description."
@valsplit is_top_level(Val(name::Symbol)) = false

"""
    @add_top_level(name, f)

Register `f` as a top-level parser for PDDL descriptions (e.g domains, problems).
"""
macro add_top_level(name, f)
    f = esc(f)
    _parse_top_level = GlobalRef(@__MODULE__, :parse_top_level)
    _is_top_level = GlobalRef(@__MODULE__, :is_top_level)
    quote
        $_parse_top_level(::Val{$name}, expr) = $f(expr)
        $_is_top_level(::Val{$name}) = true
    end
end

"Parse header field for a PDDL description."
@valsplit parse_header_field(Val(desc::Symbol), fieldname, expr) =
    error("Unrecognized description: :$desc")
@valsplit parse_header_field(desc::Union{Val,Nothing}, Val(fieldname::Symbol), expr) =
    error("Unrecognized fieldname: :$fieldname")

"Returns whether `fieldname` is a header field for a PDDL description."
@valsplit is_header_field(Val(desc::Symbol), fieldname::Symbol) = false
@valsplit is_header_field(desc::Union{Val,Nothing}, Val(fieldname::Symbol)) = false

"""
    @add_header_field(desc, fieldname, f)

Register `f` as a parser for a header field in a PDDL description.
"""
macro add_header_field(desc, fieldname, f)
    f = esc(f)
    _parse_header_field = GlobalRef(@__MODULE__, :parse_header_field)
    _is_header_field = GlobalRef(@__MODULE__, :is_header_field)
    quote
        $_parse_header_field(::Val{$desc}, ::Val{$fieldname}, expr) = $f(expr)
        $_parse_header_field(::Nothing, ::Val{$fieldname}, expr) = $f(expr)
        $_is_header_field(::Val{$desc}, ::Val{$fieldname}) = true
        $_is_header_field(::Nothing, ::Val{$fieldname}) = true
    end
end

"Parse body field for a PDDL description."
@valsplit parse_body_field(Val(desc::Symbol), fieldname, expr) =
    error("Unrecognized description: :$desc")
@valsplit parse_body_field(desc::Union{Val,Nothing}, Val(fieldname::Symbol), expr) =
    error("Unrecognized fieldname: :$fieldname")

"Returns whether `fieldname` is a body field for a PDDL description."
@valsplit is_body_field(Val(desc::Symbol), fieldname::Symbol) = false
@valsplit is_body_field(desc::Union{Val,Nothing}, Val(fieldname::Symbol)) = false

"""
    @add_body_field(desc, fieldname, f)

Register `f` as a parser for a body field in a PDDL description.
"""
macro add_body_field(desc, fieldname, f)
    f = esc(f)
    _parse_body_field = GlobalRef(@__MODULE__, :parse_body_field)
    _is_body_field = GlobalRef(@__MODULE__, :is_body_field)
    quote
        $_parse_body_field(::Val{$desc}, ::Val{$fieldname}, expr) = $f(expr)
        $_parse_body_field(::Nothing, ::Val{$fieldname}, expr) = $f(expr)
        $_is_body_field(::Val{$desc}, ::Val{$fieldname}) = true
        $_is_body_field(::Nothing, ::Val{$fieldname}) = true
    end
end

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
        if is_header_field(nothing, kw)
            return parse_header_field(nothing, kw, expr)
        elseif is_body_field(nothing, kw)
            return parse_body_field(nothing, kw, expr)
        end
        error("Keyword $kw not recognized.")
    elseif expr[1] == :define
        kw = expr[2][1]
        return parse_top_level(kw, expr)
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
