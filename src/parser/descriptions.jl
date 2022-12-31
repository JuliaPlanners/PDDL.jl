"""
$(SIGNATURES)

Parse top-level PDDL descriptions (domains, problems, etc.).
"""
function parse_description(desc::Symbol, expr::Vector)
    @assert (expr[1] == :define) "'define' keyword is missing."
    @assert (expr[2][1] == desc) "'$desc' keyword is missing."
    name = expr[2][2]
    field_exprs = ((e[1].name, e) for e in expr[3:end])
    # Parse description header (requirements, types, etc.)
    header = Dict{Symbol,Any}()
    for (fieldname::Symbol, e) in field_exprs
        if !is_header_field(Val(desc), fieldname) continue end
        if haskey(header, fieldname)
            error("Header field :$fieldname appears more than once.")
        end
        field = parse_header_field(Val(desc), fieldname, e)
        if isa(field, NamedTuple)
            merge!(header, Dict(pairs(field)))
        else
            header[fieldname] = field
        end
    end
    # Parse description body (actions, etc.)
    body = Dict{Symbol,Any}()
    for (fieldname::Symbol, e) in field_exprs
        if !is_body_field(Val(desc), fieldname) continue end
        field = parse_body_field(Val(desc), fieldname, e)
        fields = get!(body, Symbol(string(fieldname) * "s"), [])
        push!(fields, field)
    end
    return name, header, body
end
parse_description(desc::Symbol, str::AbstractString) =
    parse_description(desc, parse_string(str))
