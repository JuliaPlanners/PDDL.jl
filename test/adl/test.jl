# Test some ADL features in a grid flipping domain
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

# Test all ADL features in assembly domain
path = joinpath(dirname(pathof(PDDL)), "..", "test", "adl")

domain_str = open(f->read(f, String), joinpath(path, "assembly-domain.pddl"))
domain = parse_domain(domain_str)

problem_str = open(f->read(f, String), joinpath(path, "assembly-problem.pddl"))
problem = parse_problem(problem_str, domain.requirements)

# Our goal is to assemble a frob
state = problem.init
types = [@fol($ty(:o) <<= true) for (o, ty) in problem.objtypes]
types = [types; PDDL.type_clauses(domain.types)]

# Commit charger to assembly of frob
state = execute(domain.actions[:commit], @fol([charger, frob]), state, types)
# Once commited, we can't commit again
@test check(domain.actions[:commit], @fol([charger, frob]), state, types)[1] == false

# We can't add a tube to the frob before adding the widget and fastener
@test check(domain.actions[:assemble], @fol([tube, frob]), state, types)[1] == false
state = execute(domain.actions[:assemble], @fol([widget, frob]), state, types)
@test check(domain.actions[:assemble], @fol([tube, frob]), state, types)[1] == false
state = execute(domain.actions[:assemble], @fol([fastener, frob]), state, types)

# Having added both widget and fastener, now we can add the tube
@test check(domain.actions[:assemble], @fol([tube, frob]), state, types)[1] == true
state = execute(domain.actions[:assemble], @fol([tube, frob]), state, types)

# We've completely assembled a frob!
@test resolve(problem.goal, [state; types])[1] == true
