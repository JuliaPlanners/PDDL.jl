"Helper macro for defining cached method implementations."
macro _cached(key, signature, postcall=nothing)
    @assert signature.head == :call "Signature must be a typed function call."

    # Extract function name and arguments
    fname = signature.args[1]::Symbol
    if signature.args[2].head == :parameters
        args = signature.args[3:end]
        kwargs = signature.args[2]
    else
        args = signature.args[2:end]
        kwargs = nothing
    end
    argnames = map(args) do arg
        arg.head == :(::) ? arg.args[1] : arg
    end
    argtypes = map(args) do arg
        arg.head == :(::) ? arg.args[2] : :Any
    end
    domain = argnames[1]
    argnames = argnames[2:end]

    # Construct function expression for cached method
    call_expr = if isnothing(kwargs)
        :($fname($domain.source, $(argnames...)))
    else
        :($fname($kwargs, $domain.source, $(argnames...)))
    end
    orig_call_expr = call_expr
    if !isnothing(postcall)
        call_expr = :($postcall($call_expr))
    end
    body = :(
        if haskey($domain.caches, $key)
            cache = domain.caches[$key]
            get!(cache, ($(argnames...),)) do 
                $call_expr
            end
        else
            $orig_call_expr
        end
    )
    signature.args[1] = GlobalRef(PDDL, fname)
    if isnothing(kwargs)
        signature.args[2]= :($domain::CachedDomain)
    else
        signature.args[3]= :($domain::CachedDomain)
    end
    f_expr = Expr(:function, signature, body)

    # Construct mapping from key to method type
    m_expr = :(
        function $(GlobalRef(PDDL, :_cached_method_type))(::Val{$key})
            ($fname, ($(argtypes...),))
        end
    )
    return Expr(:block, f_expr, m_expr)
end

"Return type signature for method associated with key."
@valsplit _cached_method_type(Val(key::Symbol)) =
    error("Unrecognized method key :$key")

"Return inferred cache type for a domain type and method key."
function _infer_cache_type(D::Type{<:Domain}, key::Symbol)
    S = statetype(D)
    f, argtypes = _cached_method_type(key)
    argtypes = map(argtypes) do type
        type === Domain ? D : (type === State ? S : type)
    end
    K = Tuple{argtypes[2:end]...}
    rtypes = Base.return_types(f, argtypes)
    if f in (available, relevant)
        V = Vector{Compound}
    else
        V = length(rtypes) > 1 ? Union{rtypes...} : rtypes[1]
    end
    return Dict{K, V}
end

include("domain.jl")
include("interface.jl")

