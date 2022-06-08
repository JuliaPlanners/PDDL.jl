# Test functionality of PDDL axioms / derived predicates
@testset "axioms" begin

path = joinpath(dirname(pathof(PDDL)), "..", "test", "axioms")

domain = load_domain(joinpath(path, "domain.pddl"))
@test domain.name == Symbol("blocksworld-axioms")
@test convert(Term, domain.predicates[:above]) == pddl"(above ?x ?y)"
@test Clause(pddl"(handempty)", [pddl"(forall (?x) (not (holding ?x)))"]) in
      values(domain.axioms)

problem = load_problem(joinpath(path, "problem.pddl"))
@test problem.name == Symbol("blocksworld-problem")
@test problem.objects == @pddl("a", "b", "c")

state = initstate(domain, problem)
implementations = [
    "concrete interpreter" => (domain, state),
    "abstract interpreter" => abstracted(domain, state),
    "concrete compiler" => compiled(domain, state),
    "abstract compiler" => compiled(abstracted(domain), state)
]

@testset "axioms ($name)" for (name, (domain, _)) in implementations

    # Test forward execution of plans
    state = initstate(domain, problem)
    state = execute(domain, state, pddl"(pickup b)")
    @test domain[state => pddl"(holding b)"] ≃ true
    state = execute(domain, state, pddl"(stack b c)")
    @test domain[state => pddl"(on b c)"] ≃ true
    state = execute(domain, state, pddl"(pickup a)")
    @test domain[state => pddl"(holding a)"] ≃ true
    state = execute(domain, state, pddl"(stack a b)")
    @test domain[state => pddl"(above a c)"] ≃ true

    satisfy(domain, state, problem.goal)

    satisfiers(domain, state, problem.goal)

    # Test action availability
    state = initstate(domain, problem)
    @test Set{Term}(available(domain, state)) ==
        Set{Term}(@pddl("(pickup a)", "(pickup b)", "(pickup c)"))
        
end

end # axioms
