# Test typing in a typed gripper domain
path = joinpath(dirname(pathof(PDDL)), "..", "test", "typing")

domain_str = open(f->read(f, String), joinpath(path, "domain.pddl"))
domain = parse_domain(domain_str)
@test domain.name == Symbol("gripper-typed")
@test domain.predicates[:free] == @fol(free(G))
@test domain.predtypes[:carry] == [:ball, :gripper]
@test :gripper in keys(domain.types)

problem_str = open(f->read(f, String), joinpath(path, "problem.pddl"))
problem = parse_problem(problem_str, domain.requirements)
@test problem.name == Symbol("gripper-problem")
@test problem.objects == @fol [rooma, roomb, ball1, ball2, left, right]
@test problem.objtypes[Const(:ball1)] == :ball

state = problem.init
types = [@fol($ty(:o) <<= true) for (o, ty) in problem.objtypes]
types = [types; PDDL.type_clauses(domain.types)]
state = execute(domain.actions[:pick], @fol([ball1, rooma, left]), state, types)
@test @fol(carry(ball1, left) <<= true) in state
state = execute(domain.actions[:move], @fol([rooma, roomb]), state, types)
@test @fol(robbyat(roomb) <<= true) in state
state = execute(domain.actions[:drop], @fol([ball1, roomb, left]), state, types)
@test @fol(at(ball1, roomb) <<= true) in state

@test resolve(problem.goal, [state; types])[1] == true
