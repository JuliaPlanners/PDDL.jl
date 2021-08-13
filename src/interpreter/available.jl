"Global flag for whether to cache available actions."
const _use_available_cache = Ref(true)
"Cache of available actions for a given domain and state."
const _available_action_cache = Dict{UInt,Dict{UInt,Vector{Term}}}()

"Globally enable or disable available action cache."
use_available_action_cache!(val::Bool=true) = _use_available_cache[] = val

"Clear cache of available actions."
clear_available_action_cache!() =
    (map(empty!, values(_available_action_cache));
     empty!(_available_action_cache))
clear_available_action_cache!(domain::GenericDomain) =
    empty!(_available_action_cache[objectid(domain)])

function available(domain::GenericDomain, state::GenericState;
                   use_cache::Bool=_use_available_cache[])
    if use_cache # Look up actions in cache
        cache = get!(_available_action_cache, objectid(domain),
                     Dict{UInt,Vector{Term}}())
        state_hash = hash(state)
        if haskey(cache, state_hash) return copy(cache[state_hash]) end
    end
    # Ground all action definitions with arguments
    actions = Term[]
    for act in values(domain.actions)
        typecond = (@julog($ty(:v)) for (v, ty) in zip(act.args, act.types))
        # Include type conditions when necessary for correctness
        p = act.precond
        if has_func(p, domain) || has_derived(p, domain) || has_quantifier(p)
            conds = prepend!(flatten_conjs(p), typecond)
        elseif domain.requirements[:typing]
            conds = append!(flatten_conjs(p), typecond)
        else
            conds = flatten_conjs(p)
        end
        # Find all substitutions that satisfy preconditions
        subst = satisfiers(domain, state, conds)
        if length(subst) == 0 continue end
        for s in subst
            args = [s[v] for v in act.args if v in keys(s)]
            if any(!is_ground(a) for a in args) continue end
            term = isempty(args) ? Const(act.name) : Compound(act.name, args)
            push!(actions, term)
        end
    end
    if use_cache cache[state_hash] = copy(actions) end
    return actions
end

function available(domain::GenericDomain, state::GenericState,
                   act::GenericAction, args)
    if any(!is_ground(a) for a in args)
       error("Not all arguments are ground.")
    end
    subst = Subst(var => val for (var, val) in zip(act.args, args))
    # Construct type conditions of the form "type(val)"
    typecond = (all(ty == :object for ty in act.types) ? Term[] :
               [@julog($ty(:v)) for (v, ty) in zip(args, act.types)])
    # Check whether preconditions hold
    precond = substitute(act.precond, subst)
    conds = has_func(precond, domain) || has_quantifier(precond) ?
        [typecond; precond] : [precond; typecond]
    return satisfy(domain, state, conds)
end

available(domain::GenericDomain, state::GenericState, act::Term) =
    available(domain, state, domain.actions[act.name], act.args)
