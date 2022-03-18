@testset "set fluents" begin

# Load domain and problem
path = joinpath(dirname(pathof(PDDL)), "..", "test", "sets")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem.pddl"))

# Make sure function declarations have the right output type
@test PDDL.get_function(domain, :heard).type == :set
@test PDDL.get_function(domain, :known).type == :set

# State initialization should error if set functions are not registered yet
@test_throws Exception state = initstate(domain, problem)

# Register set theory
PDDL.Sets.@register()

state = initstate(domain, problem)
implementations = [
    "concrete interpreter" => (domain, state),
    "ground interpreter" => (ground(domain, state), state),
    "concrete compiler" => compiled(domain, state),
]

@testset "set fluents ($name)" for (name, (domain, _)) in implementations
    # Initialize state, test set membership and goal
    state = initstate(domain, problem)
    @test domain[state => pddl"(member (heard hanau) rumpelstiltskin)"] == 1
    @test domain[state => pddl"(member (heard steinau) cinderella)"] == 1
    @test domain[state => pddl"(subset (known jacob) story-set)"] == true
    @test domain[state => pddl"(subset (known wilhelm) (heard steinau))"] == false
    @test satisfy(domain, state, problem.goal) == false

    # Jacob tells stories at Steinau, Wilhem at Hanau
    state = execute(domain, state, pddl"(entertain jacob steinau)")
    state = execute(domain, state, pddl"(entertain wilhelm hanau)")
    @test domain[state => pddl"(cardinality (heard steinau))"] == 3
    @test domain[state => pddl"(cardinality (heard hanau))"] == 3

    # Both tell stories at Marburg
    state = execute(domain, state, pddl"(entertain jacob marburg)")
    state = execute(domain, state, pddl"(entertain wilhelm marburg)")
    @test domain[state => pddl"(cardinality (heard marburg))"] == 4

    # Check that goal is achieved
    @test satisfy(domain, state, problem.goal) == true
end

# Deregister set theory
PDDL.Sets.deregister!()
end # set fluents
