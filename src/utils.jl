# domain[state => f] shorthand for evaluating `f` within a domain and state
Base.getindex(domain::Domain, statevar::Pair{<:State, <:Term}) =
    evaluate(domain, first(statevar), last(statevar))
Base.getindex(domain::Domain, statevar::Pair{<:State, Symbol}) =
    evaluate(domain, first(statevar), Const(last(statevar)))
Base.getindex(domain::Domain, statevar::Pair{<:State, String}) =
    evaluate(domain, first(statevar), Parser.parse_formula(last(statevar)))

get_objects(domain::Domain, state::State) = get_objects(state)

get_objects(domain::Domain, state::State, type::Symbol) =
    Const[o for (o, ty) in get_objtypes(state)
          if ty == type || ty in get_all_subtypes(domain, type)]

function get_all_subtypes(domain::Domain, name::Symbol)
    types = get_subtypes(domain, name)
    if isempty(types) return types end
    return reduce(vcat, [get_all_subtypes(domain, ty) for ty in types], init=types)
end
