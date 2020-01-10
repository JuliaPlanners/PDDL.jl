# Test typing in a typed gripper domain
path = joinpath(dirname(pathof(PDDL)), "..", "test", "adl")

domain_str = open(f->read(f, String), joinpath(path, "flip-domain.pddl"))
domain = parse_domain(domain_str)
@test domain.name == Symbol("flip")
@test domain.predicates[:white] == @fol(white(R, C))
@test :row in keys(domain.types)

problem_str = open(f->read(f, String), joinpath(path, "flip-problem.pddl"))
problem = parse_problem(problem_str, domain.requirements)
@test problem.name == Symbol("flip-problem")
@test problem.objects == @fol [r1, r2, r3, c1, c2, c3]
@test problem.objtypes[Const(:r1)] == :row

state = problem.init
types = [@fol($ty(:o) <<= true) for (o, ty) in problem.objtypes]
types = [types; PDDL.type_clauses(domain.types)]
state = execute(domain.actions[:flip_column], @fol([c1]), state, types)
state = execute(domain.actions[:flip_column], @fol([c3]), state, types)
state = execute(domain.actions[:flip_row], @fol([r2]), state, types)

@test resolve(problem.goal, [state; types])[1] == true
