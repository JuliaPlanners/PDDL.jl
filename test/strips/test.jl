# Test basic STRIPS functionality in a gripper domain
path = joinpath(dirname(pathof(PDDL)), "..", "test", "strips")

domain_str = open(f->read(f, String), joinpath(path, "domain.pddl"))
domain = parse_domain(domain_str)
@test domain.name == :gripper
@test domain.predicates[:room] == @fol(room(R))

problem_str = open(f->read(f, String), joinpath(path, "problem.pddl"))
problem = parse_problem(problem_str)
@test problem.name == Symbol("gripper-problem")
@test problem.objects == @fol [rooma, roomb, ball1, ball2, left, right]

state = initialize(problem)
state = execute(@fol(pick(ball1, rooma, left)), state, domain)
@test satisfy(@fol(carry(ball1, left)), state)[1] == true
state = execute(@fol(move(rooma, roomb)), state, domain)
@test satisfy(@fol(robbyat(roomb)), state)[1] == true
state = execute(@fol(drop(ball1, roomb, left)), state, domain)
@test satisfy(@fol(at(ball1, roomb)), state)[1] == true

@test satisfy(problem.goal, state)[1] == true

state = initialize(problem)
plan = @fol [
    pick(ball1, rooma, left),
    move(rooma, roomb),
    drop(ball1, roomb, left)
]
state = execute(plan, state, domain)
@test satisfy(problem.goal, state)[1] == true
