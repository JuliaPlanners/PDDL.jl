# Test some ADL features in a grid flipping domain
path = joinpath(dirname(pathof(PDDL)), "..", "test", "adl")

domain = load_domain(joinpath(path, "flip-domain.pddl"))
@test domain.name == Symbol("flip")
problem = load_problem(joinpath(path, "flip-problem.pddl"))
@test problem.name == Symbol("flip-problem")

state = initialize(problem)
state = execute(@julog(flip_column(c1)), state, domain)
state = execute(@julog(flip_column(c3)), state, domain)
state = execute(@julog(flip_row(r2)), state, domain)

@test satisfy(problem.goal, state, domain)[1] == true

# Test all ADL features in assembly domain
path = joinpath(dirname(pathof(PDDL)), "..", "test", "adl")

domain = load_domain(joinpath(path, "assembly-domain.pddl"))
problem = load_problem(joinpath(path, "assembly-problem.pddl"))

# Test for static predicates
@test @julog(requires(A, R)) in get_static_predicates(domain)
@test length(get_static_predicates(domain)) == 6

# Our goal is to assemble a frob
state = initialize(problem)

# Commit charger to assembly of frob
state = execute(@julog(commit(charger, frob)), state, domain)
# Once commited, we can't commit again
@test available(@julog(commit(charger, frob)), state, domain) == false

# We can't add a tube to the frob before adding the widget and fastener
@test available(@julog(assemble(tube, frob)), state, domain) == false
state = execute(@julog(assemble(widget, frob)), state, domain)
@test available(@julog(assemble(tube, frob)), state, domain) == false
state = execute(@julog(assemble(fastener, frob)), state, domain)

# Having added both widget and fastener, now we can add the tube
@test available(@julog(assemble(tube, frob)), state, domain) == true
state = execute(@julog(assemble(tube, frob)), state, domain)

# We've completely assembled a frob!
@test satisfy(problem.goal, state, domain)[1] == true
