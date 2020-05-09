"Construct state from a list of terms (e.g. initial predicates and fluents)."
function State(terms::Vector{<:Term}, types::Vector{<:Term}=Term[])
    state = State(Set{Term}(types), Set{Term}(), Dict{Symbol,Any}())
    for t in terms
        if t.name == :(==)
            # Initialize fluents
            term, val = t.args[1], t.args[2]
            @assert !isa(term, Var) "Initial terms cannot be unbound variables."
            @assert isa(val, Const) "Terms must be initialized to constants."
            state[term] = val.name
        else
            push!(state.facts, t)
        end
    end
    return state
end

"Access the value of a fluent or fact in a state."
Base.getindex(state::State, term::Term) =
    evaluate(term, state; as_const=false)
Base.getindex(state::State, term::String) =
    evaluate(Parser.parse_formula(term), state; as_const=false)
Base.getindex(state::State, term::Union{Number,Symbol,Expr}) =
    evaluate(eval(Julog.parse_term(term)), state; as_const=false)
Base.getindex(state::State, domain::Domain, term::Term) =
    evaluate(term, state, domain; as_const=false)
Base.getindex(state::State, domain::Domain, term::String) =
    evaluate(Parser.parse_formula(term), state, domain; as_const=false)
Base.getindex(state::State, domain::Domain, term::Union{Number,Symbol,Expr}) =
    evaluate(eval(Julog.parse_term(term)), state, domain; as_const=false)

"Set the value of a fluent or fact in a state."
Base.setindex!(state::State, val::Bool, term::Const) =
    (if val push!(state.facts, term) else delete!(state.facts, term) end; val)
Base.setindex!(state::State, val::Bool, term::Compound) =
    (if val push!(state.facts, term) else delete!(state.facts, term) end; val)
Base.setindex!(state::State, val::Any, term::Const) =
    (state.fluents[term.name] = val)
Base.setindex!(state::State, val::Any, term::Compound) =
    (d = get!(state.fluents, term.name, Dict());
     d[Tuple(a.name for a in term.args)] = val)
Base.setindex!(state::State, val::Any, term::Union{Number,Symbol,Expr}) =
    Base.setindex!(state, val, eval(Julog.parse_term(term)))
