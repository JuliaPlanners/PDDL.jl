# Test functionality of PDDL axioms / derived predicates
path = joinpath(dirname(pathof(PDDL)), "..", "test", "axioms")

domain = load_domain(joinpath(path, "domain.pddl"))
@test domain.name == Symbol("blocksworld-axioms")
@test domain.predicates[:above] == pddl"(above ?x ?y)"
@test @julog(above(X, Y) <<= or(on(X, Y), and(on(X, Z), above(Z, Y)))) in domain.axioms

problem = load_problem(joinpath(path, "problem.pddl"))
@test problem.name == Symbol("blocksworld-problem")
@test problem.objects == @pddl("a", "b", "c")

state = init_state(problem)
state = execute(domain, state, pddl"(pickup b)")
@test domain:state:pddl"(holding b)" == true
state = execute(domain, state, pddl"(stack b c)")
@test domain:state:pddl"(on b c)" == true
state = execute(domain, state, pddl"(pickup a)")
@test domain:state:pddl"(holding a)" == true
state = execute(domain, state, pddl"(stack a b)")
@test domain:state:pddl"(above a c)" == true

@test satisfy(domain, state, problem.goal) == true
