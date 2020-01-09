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

state = problem.init
state = execute(domain.actions[:pick], @fol([ball1, rooma, left]), state)
@test @fol(carry(ball1, left) <<= true) in state
state = execute(domain.actions[:move], @fol([rooma, roomb]), state)
@test @fol(robbyat(roomb) <<= true) in state
state = execute(domain.actions[:drop], @fol([ball1, roomb, left]), state)
@test @fol(at(ball1, roomb) <<= true) in state

@test resolve(problem.goal, state)[1] == true
