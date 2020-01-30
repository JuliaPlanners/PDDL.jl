# Test functionality of PDDL axioms / derived predicates
path = joinpath(dirname(pathof(PDDL)), "..", "test", "axioms")

domain = load_domain(joinpath(path, "domain.pddl"))
@test domain.name == Symbol("blocksworld-axioms")
@test domain.predicates[:above] == @fol(above(X, Y))
@test @fol(above(X, Y) <<= or(on(X, Y), and(on(X, Z), above(Z, Y)))) in domain.axioms

problem = load_problem(joinpath(path, "problem.pddl"))
@test problem.name == Symbol("blocksworld-problem")
@test problem.objects == @fol [a, b, c]

state = initialize(problem)
state = execute(@fol(pickup(b)), state, domain)
@test satisfy(@fol(holding(b)), state, domain)[1] == true
state = execute(@fol(stack(b, c)), state, domain)
@test satisfy(@fol(on(b, c)), state, domain)[1] == true
state = execute(@fol(pickup(a)), state, domain)
@test satisfy(@fol(holding(a)), state, domain)[1] == true
state = execute(@fol(stack(a, b)), state, domain)
@test satisfy(@fol(above(a, c)), state, domain)[1] == true

@test satisfy(problem.goal, state, domain)[1] == true
