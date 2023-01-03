# Utilities #

macro _safe_call(call_expr, default_expr)
    @assert call_expr.head == :call "Must be a call expression."
    return quote
        try
            $(esc(call_expr))
        catch MethodError
            $(esc(default_expr))
        end
    end
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
    print(io, "\n", "  $category: ")
    max_chars = last(displaysize(io))
    objects, objtypes = collect(keys(objects)), collect(values(objects))
    objects = Writer.write_typed_list(objects, objtypes)
    objects = Writer.indent_typed_list(objects, 0, max_chars)
    lines = split(objects, "\n")
    _show_list(io, lines, limit, indent * "  ")
end

# Domains #

function Base.show(io::IO, ::MIME"text/plain", domain::Domain)
    print(io, typeof(domain))
    print(io, "\n", "  name: ", get_name(domain))

    # Extract fields
    typetree = @_safe_call(get_typetree(domain), Dict())
    predicates = @_safe_call(get_predicates(domain), Dict())
    functions = @_safe_call(get_functions(domain), Dict())
    constants = @_safe_call(get_constypes(domain), Dict())
    axioms = @_safe_call(get_axioms(domain), Dict())
    actions = @_safe_call(get_actions(domain), Dict())
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

function _line_limit(n_items::Int, remaining::Int)
    n_items == 0 && return 0
    n_items + 1 <= remaining && return n_items + 1
    n_displayed = min(remaining-1, n_items)
    return n_displayed <= 3 ? 1 : n_displayed + 1
end

function _show_typetree(io::IO, typetree, indent, limit::Int)
    isempty(typetree) && return
    print(io, "\n", "  typetree: ", summary(typetree))
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
    print(io, "\n", "  $category: ", summary(fluents))
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
    print(io, "\n", "  axioms: ", summary(axioms))
    max_chars = maximum(length.(repr.(keys(axioms))))
    axioms = ["$(rpad(repr(name), max_chars)) => " *
               Writer.write_axiom(ax) for (name, ax) in pairs(axioms)]
    sort!(axioms)
    _show_list(io, axioms, limit-1, "  " * indent)
end

function _show_actions(io::IO, actions, indent, limit::Int)
    isempty(actions) && return
    print(io, "\n", "  actions: ")
    max_chars = maximum(length.(repr.(keys(actions))))
    actions = ["$(rpad(repr(name), max_chars)) => " *
               Writer.write_action_sig(act) for (name, act) in pairs(actions)]
    sort!(actions)
    _show_list(io, actions, limit-1, "  " * indent)
end
