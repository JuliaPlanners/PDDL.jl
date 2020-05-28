module Writer

export write_pddl, write_domain, write_problem
export save_domain, save_problem

using Julog
using ..PDDL: Domain, Problem, Action, Event
using ..PDDL: DEFAULT_REQUIREMENTS, IMPLIED_REQUIREMENTS

"Write list of typed formulae in PDDL syntax."
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

"Indent list of PDDL constants."
function indent_const_list(str::String, indent::Int, maxchars::Int=80)
    if length(str) < maxchars - indent return str end
    lines = String[]
    while length(str) > 0
        l_end = min(maxchars - indent, length(str))
        if l_end != length(str) l_end = findlast(' ', str[1:l_end]) end
        if l_end == nothing l_end = findfirst(' ', str) end
        if l_end == nothing l_end = length(str) end
        push!(lines, str[1:l_end])
        str = str[l_end+1:end]
    end
    return join(lines, "\n" * ' '^indent)
end

"Indent list of typed PDDL constants."
function indent_typed_list(str::String, indent::Int, maxchars::Int=80)
    if length(str) < maxchars - indent return str end
    if !occursin(" - ", str) return indent_const_list(strs[1]) end
    substrs = String[]
    while length(str) > 0
        idxs = findnext(r" - (\S+)", str, 1)
        if idxs == nothing idxs = [length(str)] end
        push!(substrs, str[1:idxs[end]])
        str = strip(str[idxs[end]+1:end])
    end
    substrs = indent_const_list.(substrs, indent, maxchars)
    return join(substrs, "\n" * ' '^indent)
end

"Write formula in PDDL syntax."
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
    else
        args = join([write_subformula(a) for a in f.args], " ")
        return "($(f.name) $args)"
    end
end
write_formula(f::Var) = "?" * lowercasefirst(repr(f))
write_formula(f::Const) = "(" * repr(f) * ")"

write_subformula(f::Compound) = write_formula(f)
write_subformula(f::Var) = "?" * lowercasefirst(repr(f))
write_subformula(f::Const) = repr(f)

"Write to string in PDDL syntax."
write_pddl(f::Term) = write_formula(f)

"Write domain in PDDL syntax."
function write_domain(domain::Domain, indent::Int=2)
    strs = Dict{Symbol,String}()
    fields = [:requirements, :types, :constants, :predicates, :functions]
    strs[:requirements] = write_requirements(domain.requirements)
    strs[:types] = write_types(domain.types)
    strs[:constants] = indent_typed_list(
        write_typed_list(domain.constants, domain.constypes), 14)
    strs[:predicates] = write_predicates(domain.predicates, domain.predtypes)
    strs[:functions] = write_predicates(domain.functions, domain.functypes)
    strs = ["($(repr(k)) $(strs[k]))" for k in fields
            if haskey(strs, k) && length(strs[k]) > 0]
    append!(strs, write_axiom.(values(domain.axioms)))
    append!(strs, write_action.(values(domain.actions), 3))
    append!(strs, write_event.(values(domain.events), 3))
    pushfirst!(strs, "(define (domain $(domain.name))")
    return join(strs, "\n" * ' '^indent) * "\n)"
end
write_pddl(domain::Domain) = write_domain(domain)

"Write domain requirements."
function write_requirements(requirements::Dict{Symbol,Bool})
    return join([":$k" for (k, v) in requirements if v], " ")
end

"Write domain types."
function write_types(types::Dict{Symbol,Vector{Symbol}})
    strs = Dict{Symbol,String}()
    for (type, subtypes) in types
        if isempty(subtypes) || type == :object continue end
        subtype_str = join(subtypes, " ")
        strs[type] = "$subtype_str - $type"
    end
    maxtypes = collect(setdiff(types[:object], keys(strs)))
    strs[:object] = join(maxtypes, " ")
    return strip(join(values(strs), " "))
end

"Write domain predicates or functions."
function write_predicates(predicates::Dict{Symbol,Term},
                          predtypes::Dict{Symbol,Vector{Symbol}})
    strs = String[]
    for (name, pred) in predicates
        types = predtypes[name]
        args_str = write_typed_list(pred.args, types)
        push!(strs, "($name $args_str)")
    end
    return join(strs, " ")
end

"Write PDDL axiom / derived predicate."
function write_axiom(c::Clause, key=":derived")
    head_str = write_formula(c.head)
    body_str = length(c.body) == 1 ? write_formula(c.body[1]) :
        "(and " * join(write_formula.(c.body), " ") * ")"
    return "($key $head_str $body_str)"
end

"Write action in PDDL syntax."
function write_action(action::Action, indent::Int=1)
    strs = Dict{Symbol,String}()
    fields = [:action, :parameters, :precondition, :effect]
    strs[:action] = string(action.name)
    strs[:parameters] = "(" * write_typed_list(action.args, action.types) * ")"
    strs[:precondition] = write_formula(action.precond)
    strs[:effect] = write_formula(action.effect)
    strs = ["$(repr(k)) $(strs[k])" for k in fields]
    return "(" * join(strs, "\n" * ' '^indent) * ")"
end
write_pddl(action::Action) = write_action(action)

"Write event in PDDL syntax."
function write_event(event::Event, indent::Int=1)
    strs = Dict{Symbol,String}()
    fields = [:event, :precondition, :effect]
    strs[:event] = string(action.name)
    strs[:precondition] = write_formula(action.precond)
    strs[:effect] = write_formula(action.effect)
    strs = ["$(repr(k)) $(strs[k])" for k in fields]
    return "(" * join(strs, "\n" * ' '^indent) * ")"
end
write_pddl(event::Event) = write_event(event)

"Write problem in PDDL syntax."
function write_problem(problem::Problem, indent::Int=2)
    strs = Dict{Symbol,String}()
    fields = [:domain, :objects, :init, :goal, :metric]
    strs[:domain] = string(problem.domain)
    strs[:objects] = indent_typed_list(
        write_typed_list(problem.objects, problem.objtypes), 12)
    strs[:init] = write_init(problem.init, 9)
    strs[:goal] = write_formula(problem.goal)
    strs[:metric] = write_metric(problem.metric)
    strs = ["($(repr(k)) $(strs[k]))" for k in fields
            if haskey(strs, k) && length(strs[k]) > 0]
    pushfirst!(strs, "(define (problem $(problem.name))")
    return join(strs, "\n" * ' '^indent) * "\n)"
end
write_pddl(problem::Problem) = write_problem(problem)

"Write initial problem formulae in PDDL syntax."
function write_init(init::Vector{<:Term}, indent::Int=2, maxchars::Int=80)
    strs = write_formula.(init)
    if sum(length.(strs)) + length("(:init )") < maxchars
        return join(strs, " ") end
    return join(strs, "\n" * ' '^indent)
end

"Write metric for PDDL problem."
function write_metric(metric::Tuple{Int,Term})
    sign, formula = metric
    direction = sign > 0 ? "maximize" : "minimize"
    return direction * " " * write_formula(formula)
end
write_metric(::Nothing) = ""

"Save PDDL domain to specified path."
function save_domain(path::String, domain::Domain)
    open(f->write(f, write_domain(domain)), path, "w")
    return path
end

"Save PDDL problem to specified path."
function save_problem(path::String, problem::Problem)
    open(f->write(f, write_problem(problem)), path, "w")
    return path
end

end
