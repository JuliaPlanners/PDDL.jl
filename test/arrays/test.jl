@testset "array fluents" begin

# Load domain and problem
path = joinpath(dirname(pathof(PDDL)), "..", "test", "arrays")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem.pddl"))

# Make sure function declarations have the right output type
@test PDDL.get_function(domain, :walls).type == Symbol("bit-matrix")

# Register array theory
PDDL.Arrays.register!()

state = initstate(domain, problem)
implementations = [
    "concrete interpreter" => (domain, state),
    "concrete compiler" => compiled(domain, state),
]

@testset "array fluents ($name)" for (name, (domain, _)) in implementations
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
    state = execute(domain, state, pddl"(down)")
    state = execute(domain, state, pddl"(down)")
    state = execute(domain, state, pddl"(right)")
    state = execute(domain, state, pddl"(right)")
    state = execute(domain, state, pddl"(up)")
    state = execute(domain, state, pddl"(up)")

    # Check that goal is achieved
    @test satisfy(domain, state, problem.goal) == true
end

# Deregister array theory
PDDL.Arrays.deregister!()
end # array fluents
