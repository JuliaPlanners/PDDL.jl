# Test functionality of PDDL axioms / derived predicates
path = joinpath(dirname(pathof(PDDL)), "..", "test", "axioms")

domain = load_domain(joinpath(path, "domain.pddl"))
@test domain.name == Symbol("blocksworld-axioms")
@test domain.predicates[:above] == @julog(above(X, Y))
@test @julog(above(X, Y) <<= or(on(X, Y), and(on(X, Z), above(Z, Y)))) in domain.axioms

problem = load_problem(joinpath(path, "problem.pddl"))
@test problem.name == Symbol("blocksworld-problem")
@test problem.objects == @julog [a, b, c]

state = initialize(problem)
state = execute(@julog(pickup(b)), state, domain)
@test satisfy(@julog(holding(b)), state, domain)[1] == true
state = execute(@julog(stack(b, c)), state, domain)
@test satisfy(@julog(on(b, c)), state, domain)[1] == true
state = execute(@julog(pickup(a)), state, domain)
@test satisfy(@julog(holding(a)), state, domain)[1] == true
state = execute(@julog(stack(a, b)), state, domain)
@test satisfy(@julog(above(a, c)), state, domain)[1] == true

@test satisfy(problem.goal, state, domain)[1] == true
