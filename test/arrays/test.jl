@testset "array fluents" begin

# Register array theory
PDDL.Arrays.@register()

# Load gridworld domain and problem
path = joinpath(dirname(pathof(PDDL)), "..", "test", "arrays")
domain = load_domain(joinpath(path, "gridworld-domain.pddl"))
problem = load_problem(joinpath(path, "gridworld-problem.pddl"))

# Ensure that Base.show does not error
Base.show(IOBuffer(), "text/plain", problem)

# Make sure function declarations have the right output type
@test PDDL.get_function(domain, :walls).type == Symbol("bit-matrix")

state = initstate(domain, problem)
implementations = [
    "concrete interpreter" => domain,
    "ground interpreter" => ground(domain, state),
    "cached interpreter" => CachedDomain(domain),
    "concrete compiler" => first(compiled(domain, state)),
    "cached compiler" => CachedDomain(first(compiled(domain, state))),
]

@testset "gridworld ($name)" for (name, domain) in implementations
    # Initialize state, test array dimensios, access and goal
    state = initstate(domain, problem)
    @test domain[state => pddl"(width (walls))"] == 3
    @test domain[state => pddl"(height (walls))"] == 3
    @test domain[state => pddl"(get-index walls 2 2)"] == true
    @test domain[state => pddl"(get-index walls 1 2)"] == true
    @test satisfy(domain, state, problem.goal) == false

    # Check that we can only move down because of wall
    actions = available(domain, state) |> collect
    @test length(actions) == 1 && actions[1].name == :down

    # Execute plan to reach goal
    state = execute(domain, state, pddl"(down)", check=true)
    state = execute(domain, state, pddl"(down)", check=true)
    state = execute(domain, state, pddl"(right)", check=true)
    state = execute(domain, state, pddl"(right)", check=true)
    state = execute(domain, state, pddl"(up)", check=true)
    state = execute(domain, state, pddl"(up)", check=true)

    # Check that goal is achieved
    @test satisfy(domain, state, problem.goal) == true

    # Ensure that Base.show does not error
    buffer = IOBuffer()
    action = first(PDDL.get_actions(domain))
    Base.show(buffer, "text/plain", domain)
    Base.show(buffer, "text/plain", action)
    close(buffer)
end

# Test writing of array-valued fluents
original_state = initstate(domain, problem)
problem_str = write_problem(GenericProblem(original_state))
reparsed_state = initstate(domain, parse_problem(problem_str))
@test reparsed_state == original_state

# Load stairs domain and problem
path = joinpath(dirname(pathof(PDDL)), "..", "test", "arrays")
domain = load_domain(joinpath(path, "stairs-domain.pddl"))
problem = load_problem(joinpath(path, "stairs-problem.pddl"))

# Make sure function declarations have the right output type
@test PDDL.get_function(domain, :stairs).type == Symbol("num-vector")

state = initstate(domain, problem)
implementations = [
    "concrete interpreter" => domain,
    "ground interpreter" => ground(domain, state),
    "cached interpreter" => CachedDomain(domain),
    "concrete compiler" => first(compiled(domain, state)),
    "cached compiler" => CachedDomain(first(compiled(domain, state))),
]

@testset "stairs ($name)" for (name, domain) in implementations
    # Initialize state, test array dimensios, access and goal
    state = initstate(domain, problem)
    @test domain[state => pddl"(length (stairs))"] == 5
    @test domain[state => pddl"(get-index stairs 1)"] == 1.0
    @test domain[state => pddl"(get-index stairs 2)"] == 3.0
    @test satisfy(domain, state, problem.goal) == false

    # Check that we can only jump because first stair is too high
    actions = available(domain, state) |> collect
    @test length(actions) == 1 && actions[1].name == Symbol("jump-up")

    # Execute plan to reach goal
    state = execute(domain, state, pddl"(jump-up)", check=true)
    state = execute(domain, state, pddl"(climb-up)", check=true)
    state = execute(domain, state, pddl"(jump-down)", check=true)
    state = execute(domain, state, pddl"(jump-up)", check=true)
    state = execute(domain, state, pddl"(jump-up)", check=true)
    state = execute(domain, state, pddl"(jump-down)", check=true)
    state = execute(domain, state, pddl"(climb-up)", check=true)
    state = execute(domain, state, pddl"(jump-up)", check=true)

    # Check that goal is achieved
    @test satisfy(domain, state, problem.goal) == true

    # Ensure that Base.show does not error
    buffer = IOBuffer()
    action = first(PDDL.get_actions(domain))
    Base.show(buffer, "text/plain", domain)
    Base.show(buffer, "text/plain", state)
    Base.show(buffer, "text/plain", action)
    close(buffer)
end

# Deregister array theory
PDDL.Arrays.deregister!()
end # array fluents
