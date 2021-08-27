"Get domain constant type declarations as a list of clauses."
function get_const_clauses(domain::Domain)
   return [@julog($ty(:o) <<= true) for (o, ty) in get_constypes(domain)]
end

"Get domain type hierarchy as a list of clauses."
function get_type_clauses(domain::Domain)
    clauses = [[Clause(@julog($ty(X)), Term[@julog($s(X))]) for s in subtys]
               for (ty, subtys) in get_types(domain) if length(subtys) > 0]
    return length(clauses) > 0 ? reduce(vcat, clauses) : Clause[]
end

"Get all proof-relevant Horn clauses for PDDL domain."
function get_clauses(domain::Domain)
   return [collect(values(get_axioms(domain)));
           get_const_clauses(domain); get_type_clauses(domain)]
end
