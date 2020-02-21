# Test basic STRIPS functionality in a gripper domain
path = joinpath(dirname(pathof(PDDL)), "..", "test", "strips")

domain = load_domain(joinpath(path, "domain.pddl"))
@test domain.name == :gripper
@test domain.predicates[:room] == @julog(room(R))

problem = load_problem(joinpath(path, "problem.pddl"))
@test problem.name == Symbol("gripper-problem")
@test problem.objects == @julog [rooma, roomb, ball1, ball2, left, right]

state = initialize(problem)
state = execute(@julog(pick(ball1, rooma, left)), state, domain)
@test satisfy(@julog(carry(ball1, left)), state)[1] == true
state = execute(@julog(move(rooma, roomb)), state, domain)
@test satisfy(@julog(robbyat(roomb)), state)[1] == true
state = execute(@julog(drop(ball1, roomb, left)), state, domain)
@test satisfy(@julog(at(ball1, roomb)), state)[1] == true

@test satisfy(problem.goal, state)[1] == true

@test Set(available(state, domain)) == Set{Term}(@julog([
    pick(ball1, roomb, right), pick(ball1, roomb, left),
    move(roomb, rooma), move(roomb, roomb)
]))

state = initialize(problem)
plan = @julog [
    pick(ball1, rooma, left),
    move(rooma, roomb),
    drop(ball1, roomb, left)
]
state = execute(plan, state, domain)
@test satisfy(problem.goal, state)[1] == true
