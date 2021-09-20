"Convert PDDL name-with-hyphens to CamelCase type name."
function pddl_to_type_name(name)
    words = split(lowercase(string(name)), '-', keepempty=false)
    return join(uppercasefirst.(words))
end

"Returns a list of pairs from a collection, sorted by key."
sortedpairs(collection) = sort(collect(pairs(collection)), by=first)

"Returns the sorted list of keys for a collection."
sortedkeys(collection) = sort(collect(keys(collection)))
