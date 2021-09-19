@testset "array-valued fluents" begin

# Load domain and problem
path = joinpath(dirname(pathof(PDDL)), "..", "test", "arrays")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem.pddl"))

# Make sure function declarations have the right output type
@test PDDL.get_function(domain, :wallgrid).type == Symbol("bit-array")

# Register array theory
PDDL.Arrays.register!()

# Initialize state, test array dimensios, access and goal
state = initstate(domain, problem)
@test domain[state => pddl"(width (wallgrid))"] == 3
@test domain[state => pddl"(height (wallgrid))"] == 3
@test domain[state => pddl"(get-index wallgrid 2 2)"] == true
@test domain[state => pddl"(get-index wallgrid 1 2)"] == true
@test satisfy(domain, state, problem.goal) == false

# Check that we can only move down because of wall
@test available(domain, state) |> collect == Term[pddl"(down)"]

# Execute plan to reach goal
state = execute(domain, state, pddl"(down)")
state = execute(domain, state, pddl"(down)")
state = execute(domain, state, pddl"(right)")
state = execute(domain, state, pddl"(right)")
state = execute(domain, state, pddl"(up)")
state = execute(domain, state, pddl"(up)")

# Check that goal is achieved
@test satisfy(domain, state, problem.goal) == true

# Deregister array theory
PDDL.Arrays.deregister!()
end # array-valued fluents
