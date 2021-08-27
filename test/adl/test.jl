# Test some ADL features in a grid flipping domain
path = joinpath(dirname(pathof(PDDL)), "..", "test", "adl")

domain = load_domain(joinpath(path, "flip-domain.pddl"))
@test domain.name == Symbol("flip")
problem = load_problem(joinpath(path, "flip-problem.pddl"))
@test problem.name == Symbol("flip-problem")

state = initstate(domain, problem)
state = execute(domain, state, pddl"(flip_column c1)")
state = execute(domain, state, pddl"(flip_column c3)")
state = execute(domain, state, pddl"(flip_row r2)")

@test satisfy(domain, state, problem.goal) == true

# Test all ADL features in assembly domain
path = joinpath(dirname(pathof(PDDL)), "..", "test", "adl")

domain = load_domain(joinpath(path, "assembly-domain.pddl"))
problem = load_problem(joinpath(path, "assembly-problem.pddl"))

# Test for static predicates
state = initstate(domain, problem)
# @test pddl"(requires ?a ?r)" in get_static_predicates(domain, state)
# @test length(get_static_predicates(domain, state)) == 6

# Execute plan to assemble a frob

# Commit charger to assembly of frob
state = execute(domain, state, pddl"(commit charger frob)")
# Once commited, we can't commit again
@test available(domain, state, pddl"(commit charger frob)") == false

# We can't add a tube to the frob before adding the widget and fastener
@test available(domain, state, pddl"(assemble tube frob)") == false
state = execute(domain, state, pddl"(assemble widget frob)")
@test available(domain, state, pddl"(assemble tube frob)") == false
state = execute(domain, state, pddl"(assemble fastener frob)")

# Having added both widget and fastener, now we can add the tube
@test available(domain, state, pddl"(assemble tube frob)") == true
state = execute(domain, state, pddl"(assemble tube frob)")

# We've completely assembled a frob!
@test satisfy(domain, state, problem.goal) == true
