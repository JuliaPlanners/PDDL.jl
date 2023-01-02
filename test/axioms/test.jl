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
    "concrete interpreter" => domain,
    "ground interpreter" => ground(domain, state),
    "abstracted interpreter" => abstracted(domain),
    "cached interpreter" => CachedDomain(domain),
    "concrete compiler" => first(compiled(domain, state)),
    "abstract compiler" => first(compiled(abstracted(domain), state)),
    "cached compiler" => CachedDomain(first(compiled(domain, state))),
]

@testset "axioms ($name)" for (name, domain) in implementations

    # Test forward execution of plans
    state = initstate(domain, problem)
    state = execute(domain, state, pddl"(pickup b)", check=true)
    @test domain[state => pddl"(holding b)"] ≃ true
    state = execute(domain, state, pddl"(stack b c)", check=true)
    @test domain[state => pddl"(on b c)"] ≃ true
    state = execute(domain, state, pddl"(pickup a)", check=true)
    @test domain[state => pddl"(holding a)"] ≃ true
    state = execute(domain, state, pddl"(stack a b)", check=true)
    @test domain[state => pddl"(above a c)"] ≃ true

    @test satisfy(domain, state, problem.goal) ≃ true

    # Test action availability
    state = initstate(domain, problem)
    @test Set{Term}(available(domain, state)) ==
        Set{Term}(@pddl("(pickup a)", "(pickup b)", "(pickup c)"))

end

end # axioms
