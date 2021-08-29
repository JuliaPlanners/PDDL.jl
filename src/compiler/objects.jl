function generate_object_defs(domain::Domain, state::State,
                              domain_type::Symbol, state_type::Symbol)
    objects = sort(collect(get_objects(state)), by=x->x.name)
    object_ids = (; ((o.name, i) for (i, o) in enumerate(objects))...)
    get_objects_def =
        :(get_objects(::$state_type) = $(QuoteNode(Tuple(objects))))
    get_objtypes_def =
        :(get_objtypes(::$state_type) = $(QuoteNode(get_objtypes(state))))
    objectindices_def =
        :(objectindices(::$state_type) = $(QuoteNode(object_ids)))
    objectindex_def =
        :(objectindex(state::$state_type, o::Symbol) =
            getfield(objectindices(state), o))
    typed_defs = !get_requirements(domain)[:typing] ? Expr(:block) :
        generate_object_typed_defs(domain, state, domain_type, state_type)
    return Expr(:block, get_objects_def, get_objtypes_def,
                objectindices_def, objectindex_def, typed_defs)
end

function generate_object_typed_defs(domain::Domain, state::State,
                                    domain_type::Symbol, state_type::Symbol)
    object_ids = Dict()
    for type in keys(get_types(domain))
        objs = sort(get_objects(domain, state, type), by=x->x.name)
        object_ids[type] = (; ((o.name, i) for (i, o) in enumerate(objs))...)
    end
    object_ids = (; (ty => ids for (ty, ids) in object_ids)...)
    get_objects_def =
        :(get_objects(state::$state_type, type::Symbol) =
            Const.(keys(objectindices(state, type))))
    objectindices_def =
        :(objectindices(state::$state_type, type::Symbol) =
            getfield($(QuoteNode(object_ids)), type))
    objectindex_def =
        :(objectindex(state::$state_type, type::Symbol, obj::Symbol) =
            getfield(objectindices(state, type), obj))
    return Expr(:block, get_objects_def, objectindices_def, objectindex_def)
end
