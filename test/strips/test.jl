# Test basic STRIPS functionality in a gripper domain
path = joinpath(dirname(pathof(PDDL)), "..", "test", "strips")

domain = load_domain(joinpath(path, "domain.pddl"))
@test domain.name == :gripper
@test domain.predicates[:room] == @fol(room(R))

problem = load_problem(joinpath(path, "problem.pddl"))
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

@test Set(available(state, domain)) == Set{Term}(@fol([
    pick(ball1, roomb, right), pick(ball1, roomb, left),
    move(roomb, rooma), move(roomb, roomb)
]))

state = initialize(problem)
plan = @fol [
    pick(ball1, rooma, left),
    move(rooma, roomb),
    drop(ball1, roomb, left)
]
state = execute(plan, state, domain)
@test satisfy(problem.goal, state)[1] == true
