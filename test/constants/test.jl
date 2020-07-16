# Test functionality of domain constants
path = joinpath(dirname(pathof(PDDL)), "..", "test", "constants")

domain = load_domain(joinpath(path, "domain.pddl"))
@test domain.name == Symbol("taxi")
problem = load_problem(joinpath(path, "problem.pddl"))
@test problem.name == Symbol("taxi-problem")

# Check that constants are loaded correctly
@test domain.constants == @pddl("red", "green", "yellow", "blue", "intaxi")

# Check that types of constants only resolve when domain is provided
state = init_state(problem)
@test state[pddl"(pasloc red)"] == false
@test state[domain, pddl"(pasloc red)"] == true

# Execute plan and check that it succeeds
plan = @pddl(
    "(move loc6 loc5 west)",
    "(move loc5 loc0 north)",
    "(pickup loc0 red)",
    "(move loc0 loc1 east)",
    "(move loc1 loc6 south)",
    "(move loc6 loc11 south)",
    "(move loc11 loc12 east)",
    "(move loc12 loc13 east)",
    "(move loc13 loc14 east)",
    "(move loc14 loc9 north)",
    "(move loc9 loc4 north)",
    "(dropoff loc4 green)"
)
state = execute(plan, state, domain)
@test satisfy(problem.goal, state)[1] == true
