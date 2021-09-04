"Parse top-level PDDL descriptions (domains, problems, etc.)."
function parse_description(desc::Symbol, expr::Vector)
    @assert (expr[1] == :define) "'define' keyword is missing."
    @assert (expr[2][1] == desc) "'$desc' keyword is missing."
    name = expr[2][2]
    # Parse description header (requirements, types, etc.)
    header = Dict{Symbol,Any}()
    exprs = Dict(e[1].name => e for e in expr[3:end])
    for (fieldname, parser) in head_field_parsers[desc]
        field = parser(get(exprs, fieldname, nothing))
        if isa(field, NamedTuple)
            merge!(header, Dict(pairs(field)))
        else
            header[fieldname] = field
        end
    end
    # Parse description body (actions, etc.)
    body = Dict{Symbol,Any}()
    exprs = [(e[1].name, e) for e in expr[3:end]]
    for (fieldname, e) in exprs
        if !haskey(body_field_parsers[desc], fieldname) continue end
        parser = body_field_parsers[desc][fieldname]
        fieldname = Symbol(string(fieldname) * "s")
        fields = get!(body, fieldname, [])
        push!(fields, parser(e))
    end
    return name, header, body
end
parse_description(desc::Symbol, str::AbstractString) =
    parse_description(desc, parse_string(str))
