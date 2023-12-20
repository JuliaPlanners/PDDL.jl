"Evaluate formula as fully as possible."
function partialeval(domain::Domain, state::GenericState, term::Term)
    funcs = merge(global_functions(), state.values, get_funcdefs(domain))
    return eval_term(term, Subst(), funcs)
end

"Get domain constant type declarations as a list of clauses."
function get_const_clauses(domain::Domain)
   return [Clause(pddl"($ty $o)", Term[]) for (o, ty) in get_constypes(domain)]
end

"Get domain type hierarchy as a list of clauses."
function get_type_clauses(domain::Domain)
    clauses = [[Clause(pddl"($ty ?x)", Term[pddl"($s ?x)"]) for s in subtys]
               for (ty, subtys) in get_typetree(domain) if length(subtys) > 0]
    return length(clauses) > 0 ? reduce(vcat, clauses) : Clause[]
end

"Get all proof-relevant Horn clauses for PDDL domain."
function get_clauses(domain::Domain)
   return [collect(values(get_axioms(domain)));
           get_const_clauses(domain); get_type_clauses(domain)]
end

"Reorder query to ensure correctness while reducing search time."
function reorder_query(domain::Domain, query::Term)
    query = flatten_conjs(query)
    reorder_query!(domain, query)
    return query
end

function reorder_query(domain::Domain, query::Vector{<:Term})
    query = flatten_conjs(query)
    reorder_query!(domain, query)
    return query
end

function reorder_query!(domain::Domain, query::Vector{Term})
    if isempty(query) return 1 end
    priorities = Vector{Int}(undef, length(query))
    for (i, q) in enumerate(query)
        if q.name == :and || q.name == :or || q.name == :imply
            priorities[i] = reorder_query!(domain, q.args)
        elseif is_global_func(q) || is_func(q, domain)
            priorities[i] = 4
        elseif is_negation(q) || is_quantifier(q) || is_derived(q, domain)
            priorities[i] = 3
        elseif is_type(q, domain)
            priorities[i] = 2
        else
            priorities[i] = 1
        end
    end
    order = sortperm(priorities)
    permute!(query, order)
    return maximum(priorities)
end
