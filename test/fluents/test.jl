# Test fluent functionality
path = joinpath(dirname(pathof(PDDL)), "..", "test", "fluents")

domain = load_domain(joinpath(path, "domain.pddl"))
@test domain.name == Symbol("zeno-travel")
@test domain.functions[:distance] == @julog(distance(C1, C2))
@test domain.functypes[:fuel] == [:aircraft]

problem = load_problem(joinpath(path, "problem.pddl"))
tot_time, tot_fuel = Symbol("total-time"), Symbol("total-fuel-used")
@test problem.metric == (-1, @julog(4*$tot_time + 5*$tot_fuel))

state = initialize(problem)

# Person 1 boards plane 1
state = execute(@julog(board(person1, plane1, city0)), state, domain)
@test satisfy(@julog(onboard(plane1) == 1), state, domain)[1] == true

# Plane 1 flies from city 0 to city 2
state = execute(@julog(fly(plane1, city0, city2)), state, domain)
@test satisfy(@julog($tot_fuel == 3100), state, domain)[1] == true

# Person 1 debarks at city 2
state = execute(@julog(debark(person1, plane1, city2)), state, domain)
@test satisfy(@julog(at(person1, city2)), state, domain)[1] == true

# Plane 1 refuels at city 2
state = execute(@julog(refuel(plane1, city2)), state, domain)
@test satisfy(@julog(fuel(plane1) == 10232), state, domain)[1] == true

# Person 2 boards plane 1 at city2
state = execute(@julog(board(person2, plane1, city2)), state, domain)
@test satisfy(@julog(in(person2, plane1)), state, domain)[1] == true

# Plane 1 flies from city 2 to city 0
state = execute(@julog(fly(plane1, city2, city0)), state, domain)
@test satisfy(@julog($tot_fuel == 6200), state, domain)[1] == true

# Person 2 debarks at city 0
state = execute(@julog(debark(person2, plane1, city0)), state, domain)
@test satisfy(@julog(at(person2, city0)), state, domain)[1] == true

# Plane 1 refuels at city 0
state = execute(@julog(refuel(plane1, city0)), state, domain)
@test satisfy(@julog(fuel(plane1) == 10232), state, domain)[1] == true

# Plane 1 zooms from city 0 to city 1
state = execute(@julog(zoom(plane1, city0, city1)), state, domain)
@test satisfy(@julog($tot_fuel == 16370), state, domain)[1] == true

# The whole plan took 9 steps
@test satisfy(@julog($tot_time == 9), state, domain)[1] == true

# Check if goal is satisfied
@test satisfy(problem.goal, state, domain)[1] == true

# Test execution of entire plan
state = initialize(problem)
plan = @julog [
    board(person1, plane1, city0),
    fly(plane1, city0, city2),
    debark(person1, plane1, city2),
    refuel(plane1, city2),
    board(person2, plane1, city2),
    fly(plane1, city2, city0),
    debark(person2, plane1, city0),
    refuel(plane1, city0),
    zoom(plane1, city0, city1)
]
state = execute(plan, state, domain)
@test satisfy(problem.goal, state, domain)[1] == true
