# Test basic STRIPS functionality in a gripper domain
path = joinpath(dirname(pathof(PDDL)), "..", "test", "strips")

domain = load_domain(joinpath(path, "domain.pddl"))
@test domain.name == :gripper
@test domain.predicates[:room] == pddl"(room ?r)"

problem = load_problem(joinpath(path, "problem.pddl"))
@test problem.name == Symbol("gripper-problem")
@test problem.objects == @pddl("rooma", "roomb", "ball1", "ball2", "left", "right")

# Test forward execution of plans
state = init_state(problem)
state = execute(pddl"(pick ball1 rooma left)", state, domain)
@test state[pddl"(carry ball1 left)"] == true
state = execute(pddl"(move rooma roomb)", state, domain)
@test state[pddl"(robbyat roomb)"] == true
state = execute(pddl"(drop ball1 roomb left)", state, domain)
@test state[pddl"(at ball1 roomb)"] == true

@test satisfy(problem.goal, state)[1] == true

state = init_state(problem)
plan = @pddl("(pick ball1 rooma left)",
             "(move rooma roomb)",
             "(drop ball1 roomb left)")
state = execute(plan, state, domain)
@test satisfy(problem.goal, state)[1] == true

# Test action availability
state = init_state(problem)
@test Set(available(state, domain)) == Set{Term}(@pddl(
    "(pick ball1 rooma right)", "(pick ball1 rooma left)",
    "(pick ball2 rooma right)", "(pick ball2 rooma left)",
    "(move rooma roomb)", "(move rooma rooma)"
))

# Test backward regression of plans
state = goal_state(problem)
state = regress(pddl"(drop ball1 roomb left)", state, domain)
@test state[pddl"(carry ball1 left)"] == true
state = regress(pddl"(move rooma roomb)", state, domain)
@test state[pddl"(robbyat rooma)"] == true
state = regress(pddl"(pick ball1 rooma left)", state, domain)
@test state[pddl"(at ball1 rooma)"] == true
@test issubset(state, init_state(problem))

# Test action relevance
state = goal_state(problem)
@test Set(relevant(state, domain)) == Set{Term}(@pddl(
    "(drop ball1 roomb left)", "(drop ball1 roomb right)",
    "(drop ball1 roomb ball1)", "(drop ball1 roomb ball2)",
    "(drop ball1 roomb rooma)", "(drop ball1 roomb roomb)"
))
