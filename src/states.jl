"Construct state from a list of terms (e.g. initial predicates and fluents)."
function State(terms::Vector{Term})
    facts = Set{Term}()
    fluents = Dict{Symbol,Any}()
    for t in terms
        if t.name == :(==)
            # Initialize fluents
            term, val = t.args[1], t.args[2]
            @assert !isa(term, Var) "Initial terms cannot be unbound variables."
            @assert isa(val, Const) "Terms must be initialized to constants."
            if isa(term, Const)
                # Assign term to constant value
                fluents[term.name] = val.name
            else
                # Assign entry in look-up table
                lookup = get!(fluents, term.name, Dict())
                lookup[Tuple(a.name for a in term.args)] = val.name
            end
        else
            push!(facts, t)
        end
    end
    return State(facts, fluents)
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
