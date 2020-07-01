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

"Returns the list of all terms in a state."
function get_terms(state::State)
    return Term[get_types(state); get_facts(state); get_fluents(state)]
end

"Returns the list of all type declarations in a state."
function get_types(state::State)
    return collect(state.types)
end

"Returns the list of all facts in a state."
function get_facts(state::State)
    return collect(state.facts)
end

"Returns the list of all fluent terms (but not their values) in a state."
function get_fluents(state::State)
    terms = Term[]
    for (name, val) in state.fluents
        if isa(val, Dict)
            append!(terms, [Compound(name, Const.(collect(args)))
                            for args in keys(val)])
        else
            push!(terms, Const(name))
        end
    end
    return terms
end

"Returns the list of all fluent assignments in a state."
function get_assignments(state::State)
    terms = Term[]
    for (name, val) in state.fluents
        if isa(val, Dict)
            for (args, v) in val
                fluent = Compound(name, Const.(collect(args)))
                assignment = @julog(:fluent == $v)
                push!(terms, assignment)
            end
        else
            assignment = @julog($name == $val)
            push!(terms, assignment)
        end
    end
    return terms
end

Base.copy(s::State) =
    State(copy(s.types), copy(s.facts), deepcopy(s.fluents))
Base.:(==)(s1::State, s2::State) =
    s1.types == s2.types && s1.facts == s2.facts && s1.fluents == s2.fluents
Base.hash(s::State, h::UInt) =
    hash(s.fluents, hash(s.facts, hash(s.types, h)))
Base.issubset(s1::State, s2::State) =
    s1.types ⊆ s2.types && s1.facts ⊆ s2.facts &&
    (let f1 = get_fluents(s1), f2 = get_fluents(s2)
        all(f in f2 && s1[f] == s2[f] for f in f1)
    end)

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
