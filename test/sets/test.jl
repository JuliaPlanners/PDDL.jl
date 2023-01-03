@testset "set fluents" begin

# Load domain and problem
path = joinpath(dirname(pathof(PDDL)), "..", "test", "sets")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem.pddl"))
Base.show(IOBuffer(), "text/plain", problem)

# Make sure function declarations have the right output type
@test PDDL.get_function(domain, :heard).type == :set
@test PDDL.get_function(domain, :known).type == :set

# State initialization should error if set functions are not registered yet
@test_throws Exception state = initstate(domain, problem)

# Register set theory
PDDL.Sets.@register()

state = initstate(domain, problem)
implementations = [
    "concrete interpreter" => domain,
    "ground interpreter" => ground(domain, state),
    "cached interpreter" => CachedDomain(domain),
    "concrete compiler" => first(compiled(domain, state)),
    "cached compiler" => CachedDomain(first(compiled(domain, state))),
]

@testset "set fluents ($name)" for (name, domain) in implementations
    # Initialize state, test set membership and goal
    state = initstate(domain, problem)
    @test domain[state => pddl"(member (heard hanau) rumpelstiltskin)"] == 1
    @test domain[state => pddl"(member (heard steinau) cinderella)"] == 1
    @test domain[state => pddl"(subset (known jacob) story-set)"] == true
    @test domain[state => pddl"(subset (known wilhelm) (heard steinau))"] == false
    @test satisfy(domain, state, problem.goal) == false

    # Jacob tells stories at Steinau, Wilhem at Hanau
    state = execute(domain, state, pddl"(entertain jacob steinau)", check=true)
    state = execute(domain, state, pddl"(entertain wilhelm hanau)", check=true)
    @test domain[state => pddl"(cardinality (heard steinau))"] == 3
    @test domain[state => pddl"(cardinality (heard hanau))"] == 3

    # Both tell stories at Marburg
    state = execute(domain, state, pddl"(entertain jacob marburg)", check=true)
    state = execute(domain, state, pddl"(entertain wilhelm marburg)", check=true)
    @test domain[state => pddl"(cardinality (heard marburg))"] == 4

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

# Test writing of set-valued fluents
original_state = initstate(domain, problem)
problem_str = write_problem(GenericProblem(original_state))
reparsed_state = initstate(domain, parse_problem(problem_str))
@test reparsed_state == original_state

# Deregister set theory
PDDL.Sets.deregister!()
end # set fluents
