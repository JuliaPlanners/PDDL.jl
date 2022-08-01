# domain[state => f] shorthand for evaluating `f` within a domain and state
Base.getindex(domain::Domain, statevar::Pair{<:State, <:Term}) =
    evaluate(domain, first(statevar), last(statevar))
Base.getindex(domain::Domain, statevar::Pair{<:State, Symbol}) =
    evaluate(domain, first(statevar), Const(last(statevar)))
Base.getindex(domain::Domain, statevar::Pair{<:State, String}) =
    evaluate(domain, first(statevar), Parser.parse_formula(last(statevar)))

get_objects(domain::Domain, state::State) = get_objects(state)

function get_objects(domain::Domain, state::State, type::Symbol)
    return Const[o for (o, ty) in get_objtypes(state)
                 if ty == type || ty in get_all_subtypes(domain, type)]
end

"Returns all (recursive) subtypes of `type` in a domain."
function get_all_subtypes(domain::Domain, type::Symbol)
    subtypes = get_subtypes(domain, type)
    if isempty(subtypes) return subtypes end
    return reduce(vcat, [get_all_subtypes(domain, ty) for ty in subtypes],
                  init=subtypes)
end

"Returns number of objects of particular type."
get_object_count(domain::Domain, state::State, type::Symbol) =
    length(get_objects(domain, state, type))

"Returns number of objects of each type as a dictionary."
get_object_counts(domain::Domain, state::State) =
    Dict(ty => get_object_count(domain, state, ty) for ty in get_types(domain))
