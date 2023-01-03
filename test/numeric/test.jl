@testset "numeric fluents" begin

# Test numeric fluent functionality
path = joinpath(dirname(pathof(PDDL)), "..", "test", "numeric")

domain = load_domain(joinpath(path, "domain.pddl"))
@test domain.name == Symbol("zeno-travel")
@test convert(Term, domain.functions[:distance]) == pddl"(distance ?c1 ?c2)"
@test domain.functions[:fuel].argtypes == (:aircraft,)

problem = load_problem(joinpath(path, "problem.pddl"))
@test problem.metric == pddl"(minimize (+ (* 4 (total-time)) (* 5 (total-fuel-used))))"
Base.show(IOBuffer(), "text/plain", problem)

# Test for static functions
static_fluents = infer_static_fluents(domain)
@test :capacity in static_fluents
@test length(static_fluents) == 5

state = initstate(domain, problem)
implementations = [
    "concrete interpreter" => domain,
    "ground interpreter" => ground(domain, state),
    "abstracted interpreter" => abstracted(domain),
    "cached interpreter" => CachedDomain(domain),
    "concrete compiler" => first(compiled(domain, state)),
    "abstract compiler" => first(compiled(abstracted(domain), state)),
    "cached compiler" => CachedDomain(first(compiled(domain, state))),
]

@testset "numeric fluents ($name)" for (name, domain) in implementations

    # Execute plan to goal
    state = initstate(domain, problem)

    # Person 1 boards plane 1
    state = execute(domain, state, pddl"(board person1 plane1 city0)", check=true)
    @test domain[state => pddl"(onboard plane1)"] ≃ 1

    # Plane 1 flies from city 0 to city 2
    state = execute(domain, state, pddl"(fly plane1 city0 city2)", check=true)
    @test domain[state => pddl"(total-fuel-used)"] ≃ 3100

    # Person 1 debarks at city 2
    state = execute(domain, state, pddl"(debark person1 plane1 city2)", check=true)
    @test domain[state => pddl"(at person1 city2)"] ≃ true

    # Plane 1 refuels at city 2
    state = execute(domain, state, pddl"(refuel plane1 city2)", check=true)
    @test domain[state => pddl"(fuel plane1)"] ≃ 10232

    # Person 2 boards plane 1 at city2
    state = execute(domain, state, pddl"(board person2 plane1 city2)", check=true)
    @test domain[state => pddl"(in person2 plane1)"] ≃ true

    # Plane 1 flies from city 2 to city 0
    state = execute(domain, state, pddl"(fly plane1 city2 city0)", check=true)
    @test domain[state => pddl"(total-fuel-used)"] ≃ 6200

    # Person 2 debarks at city 0
    state = execute(domain, state, pddl"(debark person2 plane1 city0)", check=true)
    @test domain[state => pddl"(at person2 city0)"] ≃ true

    # Plane 1 refuels at city 0
    state = execute(domain, state, pddl"(refuel plane1 city0)", check=true)
    @test domain[state => pddl"(fuel plane1)"] ≃ 10232

    # Plane 1 zooms from city 0 to city 1
    state = execute(domain, state, pddl"(zoom plane1 city0 city1)", check=true)
    @test domain[state => pddl"(total-fuel-used)"] ≃ 16370

    # The whole plan took 9 steps
    @test domain[state => pddl"(total-time)"] ≃ 9

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
    sim = EndStateSimulator()
    state = sim(domain, state, plan)
    @test satisfy(domain, state, problem.goal) == true

    # Ensure that Base.show does not error
    buffer = IOBuffer()
    action = first(PDDL.get_actions(domain))
    Base.show(buffer, "text/plain", domain)
    Base.show(buffer, "text/plain", state)
    Base.show(buffer, "text/plain", action)
    close(buffer)

end

end # numeric fluents
