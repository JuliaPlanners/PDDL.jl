# Test functionality of PDDL axioms / derived predicates
path = joinpath(dirname(pathof(PDDL)), "..", "test", "axioms")

domain = load_domain(joinpath(path, "domain.pddl"))
@test domain.name == Symbol("blocksworld-axioms")
@test domain.predicates[:above] == pddl"(above ?x ?y)"
@test @julog(above(X, Y) <<= or(on(X, Y), and(on(X, Z), above(Z, Y)))) in domain.axioms

problem = load_problem(joinpath(path, "problem.pddl"))
@test problem.name == Symbol("blocksworld-problem")
@test problem.objects == @julog [a, b, c]

state = init_state(problem)
state = execute(pddl"(pickup b)", state, domain)
@test state[domain, pddl"(holding b)"] == true
state = execute(pddl"(stack b c)", state, domain)
@test state[domain, pddl"(on b c)"] == true
state = execute(pddl"(pickup a)", state, domain)
@test state[domain, pddl"(holding a)"] == true
state = execute(pddl"(stack a b)", state, domain)
@test state[domain, pddl"(above a c)"] == true

@test satisfy(problem.goal, state, domain)[1] == true
