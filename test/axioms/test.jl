# Test basic STRIPS functionality in a gripper domain
path = joinpath(dirname(pathof(PDDL)), "..", "test", "axioms")

domain_str = open(f->read(f, String), joinpath(path, "domain.pddl"))
domain = parse_domain(domain_str)
@test domain.name == Symbol("blocksworld-axioms")
@test domain.predicates[:above] == @fol(above(X, Y))
@test @fol(above(X, Y) <<= or(on(X, Y), and(on(X, Z), above(Z, Y)))) in domain.axioms

problem_str = open(f->read(f, String), joinpath(path, "problem.pddl"))
problem = parse_problem(problem_str)
@test problem.name == Symbol("blocksworld-problem")
@test problem.objects == @fol [a, b, c]

state = problem.init
state = execute(domain.actions[:pickup], @fol([b]), state, domain.axioms)
@test resolve(@fol(holding(b)), [state; domain.axioms])[1] == true
state = execute(domain.actions[:stack], @fol([b, c]), state, domain.axioms)
@test resolve(@fol(on(b, c)), [state; domain.axioms])[1] == true
state = execute(domain.actions[:pickup], @fol([a]), state, domain.axioms)
@test resolve(@fol(holding(a)), [state; domain.axioms])[1] == true
state = execute(domain.actions[:stack], @fol([a, b]), state, domain.axioms)
@test resolve(@fol(above(a, c)), [state; domain.axioms])[1] == true

@test resolve(problem.goal, [state; domain.axioms])[1] == true
