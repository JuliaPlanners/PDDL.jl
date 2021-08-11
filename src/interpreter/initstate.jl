"Construct initial state from problem definition."
function initstate(domain::GenericDomain, problem::GenericProblem)
    types = Term[@julog($ty(:o)) for (o, ty) in problem.objtypes]
    state = GenericState(problem.init, types)
    return state
end

"Construct goal state from problem definition."
function goalstate(domain::GenericDomain, problem::GenericProblem)
    types = Term[@julog($ty(:o)) for (o, ty) in problem.objtypes]
    state = GenericState(flatten_conjs(problem.goal), types)
    return state
end
