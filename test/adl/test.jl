# Test ADL features in a grid flipping domain & assembly domain
@testset "action description language (adl)" begin

path = joinpath(dirname(pathof(PDDL)), "..", "test", "adl")

domain = load_domain(joinpath(path, "flip-domain.pddl"))
@test domain.name == Symbol("flip")
problem = load_problem(joinpath(path, "flip-problem.pddl"))
@test problem.name == Symbol("flip-problem")
Base.show(IOBuffer(), "text/plain", problem)

state = initstate(domain, problem)
implementations = [
    "concrete interpreter" => domain,
    "ground interpreter" => ground(domain, state),
    "cached interpreter" => CachedDomain(domain),
    "concrete compiler" => first(compiled(domain, state)),
    "cached compiler" => CachedDomain(first(compiled(domain, state))),
]

@testset "flip ($name)" for (name, domain) in implementations
    state = initstate(domain, problem)

    state = execute(domain, state, pddl"(flip_column c1)", check=true)
    state = execute(domain, state, pddl"(flip_column c3)", check=true)
    state = execute(domain, state, pddl"(flip_row r2)", check=true)

    @test satisfy(domain, state, problem.goal) == true

    # Ensure that Base.show does not error
    buffer = IOBuffer()
    action = first(PDDL.get_actions(domain))
    Base.show(buffer, "text/plain", domain)
    Base.show(buffer, "text/plain", action)
    close(buffer)
end

# Test all ADL features in assembly domain
path = joinpath(dirname(pathof(PDDL)), "..", "test", "adl")

domain = load_domain(joinpath(path, "assembly-domain.pddl"))
problem = load_problem(joinpath(path, "assembly-problem.pddl"))
Base.show(IOBuffer(), "text/plain", problem)

state = initstate(domain, problem)
implementations = [
    "concrete interpreter" => domain,
    "ground interpreter" => ground(domain, state),
    "cached interpreter" => CachedDomain(domain),
    "concrete compiler" => first(compiled(domain, state)),
    "cached compiler" => CachedDomain(first(compiled(domain, state))),
]

@testset "assembly ($name)" for (name, domain) in implementations
    # Test for static fluents
    if name != "ground interpreter"
        static_fluents = infer_static_fluents(domain)
        @test :requires in static_fluents
        @test length(static_fluents) == 6
    end

    # Execute plan to assemble a frob
    state = initstate(domain, problem)

    # Commit charger to assembly of frob
    state = execute(domain, state, pddl"(commit charger frob)", check=true)
    # Once commited, we can't commit again
    @test available(domain, state, pddl"(commit charger frob)") == false

    # We can't add a tube to the frob before adding the widget and fastener
    @test available(domain, state, pddl"(assemble tube frob)") == false
    state = execute(domain, state, pddl"(assemble widget frob)", check=true)
    @test available(domain, state, pddl"(assemble tube frob)") == false
    state = execute(domain, state, pddl"(assemble fastener frob)", check=true)

    # Having added both widget and fastener, now we can add the tube
    @test available(domain, state, pddl"(assemble tube frob)") == true
    state = execute(domain, state, pddl"(assemble tube frob)", check=true)

    # We've completely assembled a frob!
    @test satisfy(domain, state, problem.goal) == true

    # Ensure that Base.show does not error
    buffer = IOBuffer()
    action = first(PDDL.get_actions(domain))
    Base.show(buffer, "text/plain", domain)
    Base.show(buffer, "text/plain", action)
    close(buffer)
end

end # action description language (adl)
