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
state = execute(domain, state, pddl"(pick ball1 rooma left)")
@test state[domain, pddl"(carry ball1 left)"] == true
state = execute(domain, state, pddl"(move rooma roomb)")
@test state[domain, pddl"(robbyat roomb)"] == true
state = execute(domain, state, pddl"(drop ball1 roomb left)")
@test state[domain, pddl"(at ball1 roomb)"] == true

@test satisfy(domain, state, problem.goal) == true

state = init_state(problem)
plan = @pddl("(pick ball1 rooma left)",
             "(move rooma roomb)",
             "(drop ball1 roomb left)")
state = execute(domain, state, plan)
@test satisfy(domain, state, problem.goal) == true

# Test action availability
state = init_state(problem)
@test Set(available(domain, state)) == Set{Term}(@pddl(
    "(pick ball1 rooma right)", "(pick ball1 rooma left)",
    "(pick ball2 rooma right)", "(pick ball2 rooma left)",
    "(move rooma roomb)", "(move rooma rooma)"
))

# Test backward regression of plans
state = goal_state(problem)
state = regress(domain, state, pddl"(drop ball1 roomb left)")
@test state[domain, pddl"(carry ball1 left)"] == true
state = regress(domain, state, pddl"(move rooma roomb)")
@test state[domain, pddl"(robbyat rooma)"] == true
state = regress(domain, state, pddl"(pick ball1 rooma left)")
@test state[domain, pddl"(at ball1 rooma)"] == true
@test issubset(state, init_state(problem))

# Test action relevance
state = goal_state(problem)
@test Set(relevant(domain, state)) == Set{Term}(@pddl(
    "(drop ball1 roomb left)", "(drop ball1 roomb right)",
    "(drop ball1 roomb ball1)", "(drop ball1 roomb ball2)",
    "(drop ball1 roomb rooma)", "(drop ball1 roomb roomb)"
))
