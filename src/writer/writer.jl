module Writer

export write_pddl, write_domain, write_problem
export save_domain, save_problem

using Julog, DocStringExtensions
using ..PDDL:
    IMPLIED_REQUIREMENTS, Domain, Problem, Action,
    get_name, get_requirements, get_typetree, get_constants, get_constypes,
    get_predicates, get_functions, get_actions, get_axioms,
    get_domain_name, get_objects, get_objtypes,
    get_init_terms, get_goal, get_metric, get_constraints,
    get_argvars, get_argtypes, get_precond, get_effect

"""
$(SIGNATURES)

Write list of typed formulae in PDDL syntax.
"""
function write_typed_list(formulae::Vector{<:Term}, types::Vector{Symbol})
    if all(x -> x == :object, types)
        return join(write_subformula.(formulae), " ")
    end
    str = ""
    for (i, (f, t)) in enumerate(zip(formulae, types))
        str *= "$(write_subformula(f)) "
        if i == length(formulae) || t != types[i+1]
            str *= "- $t "
        end
    end
    return str[1:end-1]
end

function write_typed_list(formulae::Vector{<:Term})
    formulae, types = zip([(t.args[1], t.name) for t in formulae]...)
    return write_typed_list(collect(formulae), collect(types))
end

function write_typed_list(formulae::Vector{<:Term}, types::Dict{<:Term,Symbol})
    types = Symbol[types[f] for f in formulae]
    return write_typed_list(formulae, types)
end

"""
$(SIGNATURES)

Indent list of PDDL constants.
"""
function indent_const_list(str::String, indent::Int, maxchars::Int=80)
    if length(str) < maxchars - indent return str end
    lines = String[]
    while length(str) > 0
        l_end = min(maxchars - indent, length(str))
        if l_end != length(str) l_end = findlast(' ', str[1:l_end]) end
        if isnothing(l_end) l_end = findfirst(' ', str) end
        if isnothing(l_end) l_end = length(str) end
        push!(lines, str[1:l_end])
        str = str[l_end+1:end]
    end
    return join(lines, "\n" * ' '^indent)
end

"""
$(SIGNATURES)

Indent list of typed PDDL constants.
"""
function indent_typed_list(str::String, indent::Int, maxchars::Int=80)
    if length(str) < maxchars - indent return str end
    if !occursin(" - ", str)
        return indent_const_list(str, indent, maxchars)
    end
    substrs = String[]
    while length(str) > 0
        idxs = findnext(r" - (\S+)", str, 1)
        if isnothing(idxs) idxs = [length(str)] end
        push!(substrs, str[1:idxs[end]])
        str = strip(str[idxs[end]+1:end])
    end
    substrs = indent_const_list.(substrs, indent, maxchars)
    return join(substrs, "\n" * ' '^indent)
end

"""
$(SIGNATURES)

Write formula in PDDL syntax.
"""
function write_formula(f::Compound)
    if f.name in [:exists, :forall]
        typecond, body = f.args
        var_str = write_typed_list(flatten_conjs(typecond))
        body_str = write_formula(body)
        return "($(f.name) ($var_str) $body_str)"
    elseif f.name in [:and, :or, :not, :when, :imply,
                      :(==), :>, :<, :!=, :>=, :<=, :+, :-, :*, :/,
                      :assign, :increase, :decrease,
                      Symbol("scale-up"), Symbol("scale-down")]
        name = f.name == :(==) ? "=" : string(f.name)
        args = join([write_formula(a) for a in f.args], " ")
        return "($name $args)"
    elseif isempty(f.args)
        return "($(f.name))"
    else
        args = join([write_subformula(a) for a in f.args], " ")
        return "($(f.name) $args)"
    end
end
write_formula(f::Var) = "?" * lowercasefirst(repr(f))
write_formula(f::Const) = f.name isa Symbol ? "(" * repr(f) * ")" : repr(f)
write_formula(::Nothing) = ""

write_subformula(f::Compound) = write_formula(f)
write_subformula(f::Var) = "?" * lowercasefirst(repr(f))
write_subformula(f::Const) = repr(f)

"""
$(SIGNATURES)

Write to string in PDDL syntax.
"""
write_pddl(f::Term) = write_formula(f)

"""
$(SIGNATURES)

Write domain in PDDL syntax.
"""
function write_domain(domain::Domain, indent::Int=2)
    strs = Dict{Symbol,String}()
    fields = [:requirements, :types, :constants, :predicates, :functions]
    strs[:requirements] = write_requirements(get_requirements(domain))
    strs[:types] = write_typetree(get_typetree(domain))
    strs[:constants] = indent_typed_list(
        write_typed_list(get_constants(domain), get_constypes(domain)), 14)
    strs[:predicates] = write_signatures(get_predicates(domain))
    strs[:functions] = write_signatures(get_functions(domain))
    strs = ["($(repr(k)) $(strs[k]))" for k in fields
            if haskey(strs, k) && length(strs[k]) > 0]
    append!(strs, write_axiom.(values(get_axioms(domain))))
    append!(strs, write_action.(values(get_actions(domain)), indent=3))
    pushfirst!(strs, "(define (domain $(domain.name))")
    return join(strs, "\n" * ' '^indent) * "\n)"
end
write_pddl(domain::Domain) = write_domain(domain)

"""
$(SIGNATURES)

Write domain requirements.
"""
function write_requirements(requirements::Dict{Symbol,Bool})
    reqs = Set(k for (k, v) in requirements if v)
    for (k, implied) in IMPLIED_REQUIREMENTS
        if haskey(requirements, k)
            setdiff!(reqs, implied)
        end
    end
    return join([":$r" for r in reqs], " ")
end

"""
$(SIGNATURES)

Write domain typetree.
"""
function write_typetree(typetree)
    strs = Dict{Symbol,String}()
    for (type, subtypes) in pairs(typetree)
        if isempty(subtypes) || type == :object continue end
        subtype_str = join(subtypes, " ")
        strs[type] = "$subtype_str - $type"
    end
    maxtypes = collect(union(get(typetree, :object, Symbol[]), keys(strs)))
    strs[:object] = join(sort(maxtypes), " ")
    return strip(join(values(strs), " "))
end

"""
$(SIGNATURES)

Write domain predicates or functions.
"""
function write_signatures(signatures)
    strs = String[]
    for (name, sig) in pairs(signatures)
        args = collect(Term, sig.args)
        types = collect(Symbol, sig.argtypes)
        args_str = write_typed_list(args, types)
        sig_str = isempty(args_str) ? "($name)" : "($name $args_str)"
        if sig.type != :boolean && sig.type != :numeric
            sig_str = "$sig_str - $(sig.type)"
        end
        push!(strs, sig_str)
    end
    return join(strs, " ")
end

"""
$(SIGNATURES)

Write PDDL axiom / derived predicate.
"""
function write_axiom(c::Clause; key=":derived")
    head_str = write_formula(c.head)
    body_str = length(c.body) == 1 ? write_formula(c.body[1]) :
        "(and " * join(write_formula.(c.body), " ") * ")"
    return "($key $head_str $body_str)"
end

"""
$(SIGNATURES)

Write action in PDDL syntax.
"""
function write_action(action::Action; indent::Int=1)
    strs = Dict{Symbol,String}()
    fields = [:action, :parameters, :precondition, :effect]
    strs[:action] = string(get_name(action))
    strs[:parameters] =
        "(" * write_typed_list(get_argvars(action), get_argtypes(action)) * ")"
    strs[:precondition] = write_formula(get_precond(action))
    strs[:effect] = write_formula(get_effect(action))
    strs = ["$(repr(k)) $(strs[k])" for k in fields]
    return "(" * join(strs, "\n" * ' '^indent) * ")"
end
write_pddl(action::Action) = write_action(action)

"""
$(SIGNATURES)

Write action signature in PDDL syntax.
"""
function write_action_sig(action::Action)
    name = get_name(action)
    vars = get_argvars(action)
    types = get_argtypes(action)
    if isempty(vars)
        return "($name)"
    else
        return "($name " * write_typed_list(vars, types) * ")"
    end
end

"""
$(SIGNATURES)

Write problem in PDDL syntax.
"""
function write_problem(problem::Problem, indent::Int=2)
    strs = Dict{Symbol,String}()
    fields = [:domain, :objects, :init, :goal, :metric, :constraints]
    strs[:domain] = string(problem.domain)
    strs[:objects] = indent_typed_list(
        write_typed_list(get_objects(problem), get_objtypes(problem)), 12)
    strs[:init] = write_init(get_init_terms(problem), 9)
    strs[:goal] = write_formula(get_goal(problem))
    strs[:metric] = write_formula(get_metric(problem))[2:end-1]
    strs[:constraints] = write_formula(get_constraints(problem))
    strs = ["($(repr(k)) $(strs[k]))" for k in fields
            if haskey(strs, k) && length(strs[k]) > 0]
    pushfirst!(strs, "(define (problem $(get_name(problem)))")
    return join(strs, "\n" * ' '^indent) * "\n)"
end
write_pddl(problem::Problem) = write_problem(problem)

"""
$(SIGNATURES)

Write initial problem formulae in PDDL syntax.
"""
function write_init(init::Vector{<:Term}, indent::Int=2, maxchars::Int=80)
    strs = write_formula.(init)
    if sum(length.(strs)) + length("(:init )") < maxchars
        return join(strs, " ") end
    return join(strs, "\n" * ' '^indent)
end

"""
    save_domain(path::String, domain::Domain)

Save PDDL domain to specified path.
"""
function save_domain(path::String, domain::Domain)
    open(f->write(f, write_domain(domain)), path, "w")
    return path
end

"""
    save_problem(path::String, problem::Problem)

Save PDDL problem to specified path.
"""
function save_problem(path::String, problem::Problem)
    open(f->write(f, write_problem(problem)), path, "w")
    return path
end

Base.show(io::IO, ::MIME"text/pddl", domain::Domain) =
    print(io, write_pddl(domain))
Base.show(io::IO, ::MIME"text/pddl", problem::Problem) =
    print(io, write_pddl(problem))
Base.show(io::IO, ::MIME"text/pddl", action::Action) =
    print(io, write_pddl(action))
Base.show(io::IO, ::MIME"text/pddl", term::Term) =
    print(io, write_pddl(term))

end
