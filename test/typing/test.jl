# Test typing in a typed gripper domain
path = joinpath(dirname(pathof(PDDL)), "..", "test", "typing")

domain = load_domain(joinpath(path, "domain.pddl"))
@test domain.name == Symbol("gripper-typed")
@test domain.predicates[:free] == pddl"(free ?g)"
@test domain.predtypes[:carry] == [:ball, :gripper]
@test :gripper in keys(domain.types)

problem = load_problem(joinpath(path, "problem.pddl"))
@test problem.name == Symbol("gripper-problem")
@test problem.objects == @julog [rooma, roomb, ball1, ball2, left, right]
@test problem.objtypes[Const(:ball1)] == :ball

state = init_state(problem)
state = execute(pddl"(pick ball1 rooma left)", state, domain)
@test state[pddl"(carry ball1 left)"] == true
state = execute(pddl"(move rooma roomb)", state, domain)
@test state[pddl"(robbyat roomb)"] == true
state = execute(pddl"(drop ball1 roomb left)", state, domain)
@test state[pddl"(at ball1 roomb)"] == true

@test satisfy(problem.goal, state)[1] == true

@test Set(available(state, domain)) == Set{Term}(@pddl(
    "(pick ball1 roomb right)", "(pick ball1 roomb left)",
    "(move roomb rooma)", "(move roomb roomb)"))
