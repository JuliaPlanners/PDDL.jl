# Test typing in a typed gripper domain
path = joinpath(dirname(pathof(PDDL)), "..", "test", "typing")

domain_str = open(f->read(f, String), joinpath(path, "domain.pddl"))
domain = parse_domain(domain_str)
@test domain.name == Symbol("gripper-typed")
@test domain.predicates[:free] == @fol(free(G))
@test domain.predtypes[:carry] == [:ball, :gripper]
@test :gripper in keys(domain.types)

problem_str = open(f->read(f, String), joinpath(path, "problem.pddl"))
problem = parse_problem(problem_str, domain.requirements)
@test problem.name == Symbol("gripper-problem")
@test problem.objects == @fol [rooma, roomb, ball1, ball2, left, right]
@test problem.objtypes[Const(:ball1)] == :ball

state = initialize(problem)
state = execute(@fol(pick(ball1, rooma, left)), state, domain)
@test satisfy(@fol(carry(ball1, left)), state)[1] == true
state = execute(@fol(move(rooma, roomb)), state, domain)
@test satisfy(@fol(robbyat(roomb)), state)[1] == true
state = execute(@fol(drop(ball1, roomb, left)), state, domain)
@test satisfy(@fol(at(ball1, roomb)), state)[1] == true

@test satisfy(problem.goal, state)[1] == true

@test Set(available(state, domain)) == Set{Term}(@fol([
    pick(ball1, roomb, right), pick(ball1, roomb, left),
    move(roomb, rooma), move(roomb, roomb)
]))
