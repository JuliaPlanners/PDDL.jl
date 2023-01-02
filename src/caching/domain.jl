"""
    CachedDomain{D, Ks, Vs}

Wraps an existing domain of type `D`, caching the outputs of calls to a subset
of interface methods. `Ks` is a tuple of method identifiers, and `Vs` is a 
a tuple of corresponding cache types.
"""
struct CachedDomain{D <: Domain, Ks, Vs} <: Domain
    source::D
    caches::NamedTuple{Ks,Vs}
end

"Default methods to cache in a CachedDomain."
const DEFAULT_CACHED_METHODS = [
    :available,
    :relevant,
    :infer_static_fluents,
    :infer_affected_fluents,
    :infer_axiom_hierarchy
]

"""
    CachedDomain(source::Domain)
    CachedDomain(source::Domain, method_keys)

Construct a `CachedDomain` from a `source` domain, along with the associated
caches for each cached method. A list of `method_keys` can be provided, where
each key is a `Symbol` specifying the method to be cached.

By default, the following methods are cached: `$DEFAULT_CACHED_METHODS`.
"""
function CachedDomain(source::D, method_keys=DEFAULT_CACHED_METHODS) where {D <: Domain}
    caches = (; (key => _infer_cache_type(D, key)() for key in method_keys)...)
    return CachedDomain(source, caches)
end

function CachedDomain(source::CachedDomain, method_keys=DEFAULT_CACHED_METHODS)
    return CachedDomain(source.source, method_keys)
end

get_name(domain::CachedDomain) = domain.name

get_source(domain::CachedDomain) = domain.source

get_requirements(domain::CachedDomain) = get_requirements(domain.source)

get_typetree(domain::CachedDomain) = get_typetree(domain.source)

get_datatypes(domain::CachedDomain) = get_datatypes(domain.source)

get_constants(domain::CachedDomain) = get_constants(domain.source)

get_constypes(domain::CachedDomain) = get_constypes(domain.source)

get_predicates(domain::CachedDomain) = get_predicates(domain.source)

get_functions(domain::CachedDomain) = get_functions(domain.source)

get_funcdefs(domain::CachedDomain) = get_funcdefs(domain.source)

get_fluents(domain::CachedDomain) = get_fluents(domain.source)

get_axioms(domain::CachedDomain) = get_axioms(domain.source)

get_actions(domain::CachedDomain) = get_actions(domain.source)

statetype(::Type{CachedDomain{D}}) where {D} = statetype(D)

@_cached :infer_static_fluents infer_static_fluents(domain::Domain)

@_cached :infer_affected_fluents infer_affected_fluents(domain::Domain)

@_cached :infer_axiom_hierarchy infer_axiom_hierarchy(domain::Domain)
