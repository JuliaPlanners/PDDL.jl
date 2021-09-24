abstract type CompiledState <: State end

function generate_field_type(domain::Domain, sig::Signature{N}) where {N}
    dtype = get(get_datatypes(domain), sig.type, GLOBAL_DATATYPES[sig.type])
    return N == 0 ? dtype : (dtype == Bool ? BitArray{N} : Array{dtype,N})
end

function generate_field_type(domain::AbstractedDomain, sig::Signature{N}) where {N}
    dtype = domain.interpreter.abstractions[sig.type]
    return N == 0 ? dtype : Array{dtype,N}
end

function generate_pred_init(domain::Domain, state::State,
                            sig::Signature{N}) where {N}
    if N == 0 return false end
    dims = generate_fluent_dims(domain, state, sig)
    return :(falses($(dims...)))
end

function generate_func_init(domain::Domain, state::State,
                            sig::Signature{N}) where {N}
    default = QuoteNode(defaultval(Val(sig.type)))
    if N == 0 return default end
    dims = generate_fluent_dims(domain, state, sig)
    return :(fill($default, $(dims...)))
end

function generate_func_init(domain::AbstractedDomain, state::State,
                            sig::Signature{N}) where {N}
    abstype = domain.interpreter.abstractions[sig.type]
    default = QuoteNode(abstype(defaultval(Val(sig.type))))
    if N == 0 return default end
    dims = generate_fluent_dims(domain, state, sig)
    return :(fill($default, $(dims...)))
end

function generate_state_type(domain::Domain, state::State, domain_type::Symbol)
    # Generate type definition
    state_fields = Expr[]
    for (_, pred) in sortedpairs(get_predicates(domain))
        type = generate_field_type(domain, pred)
        field = Expr(:(::), pred.name, QuoteNode(type))
        push!(state_fields, field)
    end
    for (_, fn) in sortedpairs(get_functions(domain))
        type = generate_field_type(domain, fn)
        field = Expr(:(::), fn.name, QuoteNode(type))
        push!(state_fields, field)
    end
    if domain isa AbstractedDomain
        name = "CompiledAbstracted" * pddl_to_type_name(get_name(domain)) * "State"
    else
        name = "Compiled" * pddl_to_type_name(get_name(domain)) * "State"
    end
    state_type = gensym(name)
    state_typesig = Expr(:(<:), state_type, QuoteNode(CompiledState))
    state_typedef = :(@auto_hash_equals $(Expr(:struct, true, state_typesig,
                                               Expr(:block, state_fields...))))
    state_constructor_defs =
        generate_state_constructors(domain, state, domain_type, state_type)
    state_method_defs =
        generate_state_methods(domain, state, domain_type, state_type)
    state_defs = Expr(:block, state_constructor_defs, state_method_defs)
    return (state_type, state_typedef, state_defs)
end

function generate_state_constructors(domain::Domain, state::State,
                                     domain_type::Symbol, state_type::Symbol)
    # Generate constructor with no arguments
    state_inits = []
    state_copies = Expr[]
    for (name, pred) in sortedpairs(get_predicates(domain))
        push!(state_inits, generate_pred_init(domain, state, pred))
        push!(state_copies, :(copy(state.$name)))
    end
    for (name, fn) in sortedpairs(get_functions(domain))
        push!(state_inits, generate_func_init(domain, state, fn))
        push!(state_copies, :(copy(state.$name)))
    end
    state_constructor_defs = quote
        $state_type() = $state_type($(state_inits...))
        $state_type(state::$state_type) = $state_type($(state_copies...))
        function $state_type(state::State)
            new = $state_type()
            for (term, val) in get_fluents(state)
                if val === false continue end
                set_fluent!(new, val, term)
            end
            return new
        end
    end
    return state_constructor_defs
end

function generate_state_methods(domain::Domain, state::State,
                                domain_type::Symbol, state_type::Symbol)
    # Construct domaintype and statetype methods
    types_def = quote
        domaintype(::Type{$state_type}) = $domain_type
        domaintype(::$state_type) = $domain_type
        statetype(::Type{$domain_type}) = $state_type
        statetype(::$domain_type) = $state_type
        get_domain(::$state_type) = $domain_type()
    end
    # Fluent name listing
    get_fluent_names_def = quote
        function get_fluent_names(state::$state_type)
            domain = get_domain(state)
            f = name -> begin
                grounded_args = groundargs(domain, state, name)
                return (!isempty(args) ? Compound(name, collect(args)) :
                        Const(name) for args in grounded_args)
            end
            fluents = Base.Generator(f, fieldnames($state_type))
            return Iterators.flatten(fluents)
        end
    end
    # Fluent accessors
    get_fluent_defs, set_fluent_defs, groundargs_defs = [], [], []
    for (name, sig) in pairs(get_fluents(domain))
        # Ground args
        def = generate_groundargs(domain, state, domain_type, state_type, name)
        push!(groundargs_defs, def)
        # Only generate for compound terms
        if length(sig.args) == 0 continue end
        term = convert(Term, sig)
        args = [Symbol(:arg, i) for i in 1:length(sig.args)]
        varmap = Dict(a => :($(Symbol(:arg, i)).name)
                      for (i, a) in enumerate(sig.args))
        idxs = generate_fluent_ids(domain, state, term, sig, varmap)
        valtype = QuoteNode(Val{name})
        # Getter
        get_fluent_def = quote
            function get_fluent(state::$state_type, ::$valtype, $(args...))
                return (state.$name)[$(idxs...)]
            end
        end
        push!(get_fluent_defs, get_fluent_def)
        # Setter
        set_fluent_def = quote
            function set_fluent!(state::$state_type, val, ::$valtype, $(args...))
                state.$name[$(idxs...)] = val
            end
        end
        push!(set_fluent_defs, set_fluent_def)
    end
    state_method_defs = Expr(:block, types_def,
        get_fluent_names_def, groundargs_defs...,
        get_fluent_defs..., set_fluent_defs...)
    return state_method_defs
end

function generate_groundargs(domain::Domain, state::State,
                             domain_type::Symbol, state_type::Symbol,
                             fluent::Symbol)
    sig = get_fluent(domain, fluent)
    argtypes = sig.argtypes
    if get_requirements(domain)[:typing]
        objs_exprs = [:(get_objects(state, $(QuoteNode(ty)))) for ty in argtypes]
    else
        objs_exprs = [:(get_objects(state)) for ty in argtypes]
    end
    iter_expr = :(Iterators.product($(objs_exprs...)))
    valtype = QuoteNode(Val{fluent})
    groundargs_def = quote
        function groundargs(domain::$domain_type, state::$state_type,
                            fluent::$valtype)
            return $iter_expr
        end
    end
    return groundargs_def
end

function (::Type{S})(state::State) where {S <: CompiledState}
    new = S()
    for (term, val) in get_fluents(state)
        if val === false continue end
        set_fluent!(new, val, term)
    end
    return new
end

Base.copy(state::S) where {S <: CompiledState} =
    S(state)

groundargs(domain::CompiledDomain, state::State, fluent::Symbol) =
    groundargs(domain, state, Val(fluent))

get_fluent(state::CompiledState, term::Symbol) =
    getproperty(state, term)
get_fluent(state::CompiledState, term::Symbol, args::Vararg{Any,N}) where {N} =
    get_fluent(state, Val(term), args...)
get_fluent(state::CompiledState, term::Const) =
    get_fluent(state, term.name)
get_fluent(state::CompiledState, term::Compound) =
    get_fluent(state, term.name, term.args...)

set_fluent!(state::CompiledState, val, name::Symbol) =
    setproperty!(state, name, val)
set_fluent!(state::CompiledState, val, term::Symbol, args::Vararg{Any,N}) where {N} =
    set_fluent!(state, val, Val(term), args...)
set_fluent!(state::CompiledState, val, term::Const) =
    set_fluent!(state, val, term.name)
set_fluent!(state::CompiledState, val, term::Compound) =
    set_fluent!(state, val, term.name, term.args...)

get_fluents(state::CompiledState) =
    (term => get_fluent(state, term) for term in get_fluent_names(state))

get_facts(state::CompiledState) =
    (term for term in get_fluent_names(state)
     if get_fluent(state, term) in (true, both))
