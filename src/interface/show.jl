# Utilities #

macro _maybe(call_expr, default_expr)
    @assert call_expr.head == :call "Must be a call expression."
    return quote
        try
            $(esc(call_expr))
        catch MethodError
            $(esc(default_expr))
        end
    end
end

function _line_limit(n_items::Int, remaining::Int)
    n_items == 0 && return 0
    n_items + 1 <= remaining && return n_items + 1
    n_displayed = min(remaining-1, n_items)
    return n_displayed <= 3 ? 1 : n_displayed + 1
end

function _show_list(io::IO, list, limit::Int, indent)
    if length(list) > limit
        limit < 3 && return
        for line in list[1:(limit÷2-1)]
            print(io, "\n", indent, line)
        end
        print(io, "\n", indent, "⋮")
        for line in list[end-(limit÷2)+1:end]
            print(io, "\n", indent, line)
        end
    else
        for line in list
            print(io, "\n", indent, line)
        end
    end
end

function _show_objects(io::IO, objects, category, indent, limit::Int)
    isempty(objects) && return
    objects, objtypes = collect(keys(objects)), collect(values(objects))
    print(io, "\n", indent, "$category: ", summary(objects))
    if all(objtypes .== :object)
        objects = sort!(string.(objects))
        _show_list(io, objects, limit, indent * "  ")
    else
        objects = string.(objects)
        objtypes = string.(objtypes)
        order = sortperm(collect(zip(objtypes, objects)))
        objects = objects[order]
        objtypes = objtypes[order]
        max_chars = maximum(length.(objects))
        lines = ["$(rpad(obj, max_chars))  -  $type"
                 for (obj, type) in zip(objects, objtypes)]
        _show_list(io, lines, limit-1, indent * "  ")
    end
end

# Domains #

function Base.show(io::IO, ::MIME"text/plain", domain::Domain)
    print(io, typeof(domain))
    print(io, "\n", "  name: ", get_name(domain))

    # Extract fields
    typetree = @_maybe(get_typetree(domain), Dict())
    predicates = @_maybe(get_predicates(domain), Dict())
    functions = @_maybe(get_functions(domain), Dict())
    constants = @_maybe(get_constypes(domain), Dict())
    axioms = @_maybe(get_axioms(domain), Dict())
    actions = @_maybe(get_actions(domain), Dict())
    typing = !isempty(typetree) && collect(keys(typetree)) != [:object]

    # Compute line quotas based on display size
    remaining = get(io, :limit, false) ? first(displaysize(io)) - 6 : 80
    max_action_lines = _line_limit(length(actions), remaining)
    remaining -= max_action_lines
    max_axiom_lines = _line_limit(length(axioms), remaining)
    remaining -= max_axiom_lines
    max_constant_lines = _line_limit(length(constants), remaining)
    remaining -= max_constant_lines
    max_function_lines = _line_limit(length(functions), remaining)
    remaining -= max_function_lines
    max_predicate_lines = _line_limit(length(predicates), remaining)
    remaining -= max_predicate_lines
    max_typetree_lines = _line_limit(length(typetree), remaining)

    # Display fields
    typing && _show_typetree(io, typetree, "  ", max_typetree_lines)
    _show_predicates(io, predicates, "  ", typing, max_predicate_lines)
    _show_functions(io, functions, "  ", typing, max_function_lines)
    _show_objects(io, constants, "constants", "  ", max_constant_lines)
    _show_axioms(io, axioms, "  ", max_axiom_lines)
    _show_actions(io, actions, "  ", max_action_lines)
end

function _show_typetree(io::IO, typetree, indent, limit::Int)
    isempty(typetree) && return
    print(io, "\n", indent, "typetree: ", summary(typetree))
    max_chars = maximum(length.(repr.(keys(typetree))))
    types = get_sorted_types(typetree)
    subtypes = [typetree[ty] for ty in types]
    typetree = ["$(rpad(repr(name), max_chars)) => $(isempty(ts) ? "[]" : ts)"
                for (name, ts) in zip(types, subtypes)]
    _show_list(io, typetree, limit-1, "  " * indent)
end

function _show_fluents(io::IO, fluents, category, indent,
                       typing::Bool, limit::Int)
    isempty(fluents) && return
    print(io, "\n", indent, "$category: ", summary(fluents))
    max_chars = maximum(length.(repr.(keys(fluents))))
    names = [rpad(repr(name), max_chars) for name in keys(fluents)]
    sigs = [typing ? repr(sig) : write_pddl(convert(Term, sig))
            for sig in values(fluents)]
    fluents = ["$name => $sig" for (name, sig) in zip(names, sigs)] |> sort!
    _show_list(io, fluents, limit-1, "  " * indent)
end

_show_predicates(io::IO, predicates, indent, typing::Bool, limit::Int) =
    _show_fluents(io, predicates, "predicates", indent, typing, limit)

_show_functions(io::IO, functions, indent, typing::Bool, limit::Int) =
    _show_fluents(io, functions, "functions", indent, typing, limit)

function _show_axioms(io::IO, axioms, indent, limit::Int)
    isempty(axioms) && return
    print(io, "\n", indent, "axioms: ", summary(axioms))
    max_chars = maximum(length.(repr.(keys(axioms))))
    axioms = ["$(rpad(repr(name), max_chars)) => " *
               Writer.write_axiom(ax) for (name, ax) in pairs(axioms)]
    sort!(axioms)
    _show_list(io, axioms, limit-1, "  " * indent)
end

function _show_actions(io::IO, actions, indent, limit::Int)
    isempty(actions) && return
    print(io, "\n", indent, "actions: ")
    max_chars = maximum(length.(repr.(keys(actions))))
    actions = ["$(rpad(repr(name), max_chars)) => " *
               Writer.write_action_sig(act) for (name, act) in pairs(actions)]
    sort!(actions)
    _show_list(io, actions, limit-1, "  " * indent)
end

# Problems #

function Base.show(io::IO, ::MIME"text/plain", problem::Problem)
    print(io, typeof(problem))
    print(io, "\n", "  name: ", get_name(problem))

    # Extract fields
    domain = @_maybe(get_domain_name(domain), nothing)
    objects = @_maybe(get_objtypes(problem), Dict())
    init = @_maybe(get_init_terms(problem), Term[])
    goal = @_maybe(get_goal(problem), nothing)
    metric = @_maybe(get_metric(problem), nothing)
    constraints = @_maybe(get_constraints(problem), nothing)

    # Compute line quotas based on display size
    remaining = get(io, :limit, false) ? first(displaysize(io)) - 10 : 80
    max_object_lines = _line_limit(length(objects), remaining)
    remaining -= max_object_lines
    max_init_lines = _line_limit(length(init), remaining)

    # Display fields
    if !isnothing(domain)
        print(io, "\n", "  domain: ", domain)
    end
    _show_objects(io, objects, "objects", "  ", max_object_lines)
    _show_init(io, init, "  ", max_init_lines)
    if !isnothing(goal)
        print(io, "\n", "  goal: ", write_pddl(goal))
    end
    if !isnothing(metric)
        print(io, "\n", "  metric: ", write_pddl(metric))
    end
    if !isnothing(constraints)
        print(io, "\n", "  constraints: ", write_pddl(constraints))
    end
end

function _show_init(io::IO, init, indent, limit::Int)
    isempty(init) && return
    print(io, "\n", indent, "init: ", summary(init))
    init = sort!(write_pddl.(init))
    _show_list(io, init, limit-1, "  " * indent)
end

# States #

function Base.show(io::IO, ::MIME"text/plain", state::State)
    print(io, typeof(state))

    # Extract fields
    objects = @_maybe(get_objtypes(state), Dict())
    fluents = @_maybe(Dict(get_fluents(state)), Dict())

    # Compute line quotas based on display size
    remaining = get(io, :limit, false) ? first(displaysize(io)) - 5 : 80
    max_fluent_lines = _line_limit(length(fluents), remaining)
    remaining -= max_fluent_lines
    max_object_lines = _line_limit(length(objects), remaining)

    # Display fields
    _show_state_objects(io, objects, "  ", max_object_lines)
    _show_state_fluents(io, fluents, "  ", max_fluent_lines)
end

function _show_state_objects(io::IO, objects, indent, limit::Int)
    isempty(objects) && return
    objects, objtypes = collect(keys(objects)), collect(values(objects))
    if all(objtypes .== :object)
        print(io, "\n", indent, "objects: ", length(objects), " (untyped)")
        objects = sort!(string.(objects))
        _show_list(io, objects, limit, indent * "  ")
    else
        print(io, "\n", indent, "objects: ", length(objects), " (typed)")
        objects = string.(objects)
        objtypes = string.(objtypes)
        order = sortperm(collect(zip(objtypes, objects)))
        objects = objects[order]
        objtypes = objtypes[order]
        max_chars = maximum(length.(objects))
        lines = ["$(rpad(obj, max_chars))  -  $type"
                 for (obj, type) in zip(objects, objtypes)]
        _show_list(io, lines, limit - 1, indent * "  ")
    end
end

function _show_state_fluents(io::IO, fluents, indent, limit::Int)
    isempty(fluents) && return
    fluents, vals = collect(keys(fluents)), collect(values(fluents))
    ftype = infer_datatype(eltype(vals))
    type_desc = isnothing(ftype) ? " (mixed)" : " ($ftype)"
    print(io, "\n", indent, "fluents: ", length(fluents), type_desc)
    fluents = write_pddl.(fluents)
    max_chars = maximum(length.(fluents))
    lines = ["$(rpad(f, max_chars)) => $v" for (f, v) in zip(fluents, vals)]
    sort!(lines)
    _show_list(io, lines, limit, indent * "  ")
end

# Actions #

function Base.show(io::IO, ::MIME"text/plain", action::Action)
    print(io, typeof(action))
    print(io, "\n", "  name: ", get_name(action))

    # Extract fields
    vars = @_maybe(get_argvars(action), Var[])
    types = @_maybe(get_argtypes(action), Symbol[])
    precond = @_maybe(get_precond(action), nothing)
    effect = @_maybe(get_effect(action), nothing)

    # Display fields
    if !isempty(vars)
        parameters = "(" * Writer.write_typed_list(vars, types) * ")"
        print(io, "\n", "  parameters: ", parameters)
    end
    if !isnothing(precond) && precond != Const(true)
        print(io, "\n", "  precond: ", write_pddl(precond))
    end
    if !isnothing(effect)
        print(io, "\n", "  effect: ", write_pddl(effect))
    end
end
