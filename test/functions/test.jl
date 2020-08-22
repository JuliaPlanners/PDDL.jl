# Test external function calls / semantic attachments
path = joinpath(dirname(pathof(PDDL)), "..", "test", "functions")

# Load domain and define external functions
domain = load_domain(joinpath(path, "domain.pddl"))
throw_range(v, θ) = v^2*sin(2*θ*π/180) / 9.81
domain.funcdefs[:range] = throw_range
throw_height(v, θ, x) = tan(θ*π/180)*x - 9.81*x^2 / (2*v^2 * cos(θ*π/180)^2)
domain.funcdefs[:height] = throw_height

# Load problem
problem = load_problem(joinpath(path, "problem.pddl"))
state = init_state(problem)

# Check that evaluation with external functions works correctly
@test state[domain, pddl"(range 20 45)"] == throw_range(20, 45)
@test state[domain, pddl"(height 20 45 10)"] == throw_height(20, 45, 10)

# Execute plan
state = init_state(problem)
state = execute(pddl"(pick ball1)", state, domain)
state = execute(pddl"(throw ball1 85)", state, domain)
state = execute(pddl"(pick ball2)", state, domain)
state = execute(pddl"(throw ball2 75)", state, domain)

# Check if goal is satisfied
@test state[pddl"(< (loc ball1) 10)"]
@test state[pddl"(> (loc ball2) 15)"]
@test satisfy(problem.goal, state, domain)[1] == true
