"Generic PDDL state description."
mutable struct GenericState <: State
    types::Set{Compound} # Object type declarations
    facts::Set{Term} # Boolean-valued fluents
    values::Dict{Symbol,Any} # All other fluents
end

GenericState(types) = GenericState(types, Set{Term}(), Dict{Symbol,Any}())
GenericState(types, facts) = GenericState(types, facts, Dict{Symbol,Any}())

GenericState(state::GenericState) = copy(state)
function GenericState(state::State)
    types = Set{Compound}((Compound(ty, [o]) for (o, ty) in get_objtypes(state)))
    new = GenericState(types)
    for (term, val) in get_fluents(state)
        if val === false continue end
        set_fluent!(new, val, term)
    end
    return new
end

Base.copy(s::GenericState) =
    GenericState(copy(s.types), copy(s.facts), deepcopy(s.values))
Base.:(==)(s1::GenericState, s2::GenericState) =
    issetequal(s1.types, s2.types) && issetequal(s1.facts, s2.facts) &&
    isequal(s1.values, s2.values)
Base.hash(s::GenericState, h::UInt) =
    hash(s.values, hash(s.facts, hash(s.types, h)))
Base.issubset(s1::GenericState, s2::GenericState) =
    s1.types ⊆ s2.types && s1.facts ⊆ s2.facts

stateindex(domain::GenericDomain, state::GenericState) =
    hash(state)

get_objects(state::GenericState) =
    Const[ty.args[1] for ty in state.types]

get_objects(state::GenericState, type::Symbol) =
    Const[ty.args[1] for ty in state.types if ty.name == type]

get_objtypes(state::GenericState) =
    Dict(ty.args[1] => ty.name for ty in state.types)

get_facts(state::GenericState) =
    state.facts

function get_fluent(state::GenericState, term::Const)
    if term in state.facts
        return true
    elseif !(term.name isa Symbol) || is_global_func(term)
        error("$(write_pddl(term)) is not a fluent, use `evaluate` instead.")
    else
        return get(state.values, term.name, false)
    end
end

function get_fluent(state::GenericState, term::Compound)
    if term in state.facts
        return true
    else
        d = get(state.values, term.name, nothing)
        if !isnothing(d)
            return get(d, Tuple(a.name for a in term.args)) do
                error("Fluent $term undefined for arguments $(term.args)")
            end
        elseif is_logical_op(term) || is_global_func(term)
            error("$(write_pddl(term)) is not a fluent, use `evaluate` instead.")
        else
            return false
        end
    end
end

function set_fluent!(state::GenericState, val::Bool, term::Compound)
    if val push!(state.facts, term) else delete!(state.facts, term) end
    return val
end

function set_fluent!(state::GenericState, val::Bool, term::Const)
    if val push!(state.facts, term) else delete!(state.facts, term) end
    return val
end

function set_fluent!(state::GenericState, val::Any, term::Const)
    if !(term.name isa Symbol) || is_global_func(term)
        error("$(write_pddl(term)) is not a fluent and cannot be set.")
    end
    state.values[term.name] = val
end

function set_fluent!(state::GenericState, val::Any, term::Compound)
    d = get!(state.values, term.name) do
        is_logical_op(term) || is_global_func(term) ?
            error("$(write_pddl(term)) is not a fluent and cannot be set") : Dict()
    end
    d[Tuple(a.name for a in term.args)] = val
end

get_fluents(state::GenericState) =
    ((name => get_fluent(state, name)) for name in get_fluent_names(state))

function get_fluent_names(state::GenericState)
    f = x -> begin
        name, val = x
        if isa(val, Dict)
            return (Compound(name, Const.(collect(args))) for args in keys(val))
        else
            return (Const(name),)
        end
    end
    fluent_names = Iterators.flatten(Base.Generator(f, state.values))
    return Iterators.flatten((state.facts, fluent_names))
end

get_fluent_values(state::GenericState) =
    (get_fluent(state, name) for name in get_fluent_names(state))
