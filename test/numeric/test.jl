# Test numeric fluent functionality
path = joinpath(dirname(pathof(PDDL)), "..", "test", "numeric")

domain = load_domain(joinpath(path, "domain.pddl"))
@test domain.name == Symbol("zeno-travel")
@test convert(Term, domain.functions[:distance]) == pddl"(distance ?c1 ?c2)"
@test domain.functions[:fuel].argtypes == (:aircraft,)

problem = load_problem(joinpath(path, "problem.pddl"))
@test problem.metric == (-1, pddl"(+ (* 4 (total-time)) (* 5 (total-fuel-used)))")

# Test for static functions
state = initstate(domain, problem)
# @test pddl"(capacity ?a)" in get_static_functions(domain, state)
# @test length(get_static_functions(domain, state)) == 5

# Person 1 boards plane 1
state = execute(domain, state, pddl"(board person1 plane1 city0)")
@test domain:state:pddl"(onboard plane1)" == 1

# Plane 1 flies from city 0 to city 2
state = execute(domain, state, pddl"(fly plane1 city0 city2)")
@test domain:state:pddl"(total-fuel-used)" == 3100

# Person 1 debarks at city 2
state = execute(domain, state, pddl"(debark person1 plane1 city2)")
@test domain:state:pddl"(at person1 city2)" == true

# Plane 1 refuels at city 2
state = execute(domain, state, pddl"(refuel plane1 city2)")
@test domain:state:pddl"(fuel plane1)" == 10232

# Person 2 boards plane 1 at city2
state = execute(domain, state, pddl"(board person2 plane1 city2)")
@test domain:state:pddl"(in person2 plane1)" == true

# Plane 1 flies from city 2 to city 0
state = execute(domain, state, pddl"(fly plane1 city2 city0)")
@test domain:state:pddl"(total-fuel-used)" == 6200

# Person 2 debarks at city 0
state = execute(domain, state, pddl"(debark person2 plane1 city0)")
@test domain:state:pddl"(at person2 city0)" == true

# Plane 1 refuels at city 0
state = execute(domain, state, pddl"(refuel plane1 city0)")
@test domain:state:pddl"(fuel plane1)" == 10232

# Plane 1 zooms from city 0 to city 1
state = execute(domain, state, pddl"(zoom plane1 city0 city1)")
@test domain:state:pddl"(total-fuel-used)" == 16370

# The whole plan took 9 steps
@test domain:state:pddl"(total-time)" == 9

# Check if goal is satisfied
@test satisfy(domain, state, problem.goal) == true

# Test execution of entire plan
state = initstate(domain, problem)
plan = @pddl(
    "(board person1 plane1 city0)",
    "(fly plane1 city0 city2)",
    "(debark person1 plane1 city2)",
    "(refuel plane1 city2)",
    "(board person2 plane1 city2)",
    "(fly plane1 city2 city0)",
    "(debark person2 plane1 city0)",
    "(refuel plane1 city0)",
    "(zoom plane1 city0 city1)"
)
state = execute(domain, state, plan)
@test satisfy(domain, state, problem.goal) == true
