function generate_state_type(domain::Domain, state::State,
                             domain_type::Symbol)
    # Generate typedef
    state_fields = []
    for (_, pred) in sort(collect(get_predicates(domain)), by=first)
        n_args = length(pred.args)
        type = domain isa AbstractedDomain ?
            (n_args == 0 ? BooleanAbs : Array{BooleanAbs, n_args}) :
            (n_args == 0 ? Bool : BitArray{n_args})
        field = Expr(:(::), pred.name, QuoteNode(type))
        push!(state_fields, field)
    end
    for (_, fn) in sort(collect(get_functions(domain)), by=first)
        n_args = length(fn.args)
        # TODO: Actually use abstractions specified by abstraction function
        type = domain isa AbstractedDomain ?
            (n_args == 0 ? IntervalAbs{Float64} :
                           Array{IntervalAbs{Float64}, n_args}) :
            (n_args == 0 ? Float64 : Array{Float64, n_args})
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
    # Generate constructor with no arguments
    state_inits = []
    for (_, pred) in sort(collect(get_predicates(domain)), by=first)
        if length(pred.args) == 0
            push!(state_inits, false)
        else
            dims = fluent_dims(domain, state, pred)
            push!(state_inits, :(falses($(dims...))))
        end
    end
    for (_, fn) in sort(collect(get_functions(domain)), by=first)
        if length(fn.args) == 0
            if domain isa AbstractedDomain
                push!(state_inits, IntervalAbs(0.0))
            else
                push!(state_inits, 0.0)
            end
        else
            dims = fluent_dims(domain, state, fn)
            if domain isa AbstractedDomain
                push!(state_inits, :(fill(IntervalAbs(0.0), $(dims...))))
            else
                push!(state_inits, :(zeros($(dims...))))
            end
        end
    end
    state_constructor_defs = quote
        $state_type() = $state_type($(state_inits...))
        $state_type(state::$state_type) = copy(state)
    end
    state_copy_def = :(Base.copy(state::$state_type) = deepcopy(state))
    state_defs = Expr(:block, state_constructor_defs, state_copy_def)
    return (state_type, state_typedef, state_defs)
end
