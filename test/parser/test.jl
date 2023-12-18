# Test parsing functionality

@testset "parser" begin

@testset "formula parsing" begin

@test parse_pddl("(ball)") == Const(:ball)
@test parse_pddl("(1)") == Const(1)
@test parse_pddl("(1.0)") == Const(1.0)
@test parse_pddl("(1.0f)") == Const(1.0f0)
@test parse_pddl("(1f)") == Const(1.0f0)
@test parse_pddl("(?x)") == Var(:X)
@test parse_pddl("(on a b)") == Compound(:on, [Const(:a), Const(:b)])
@test parse_pddl("(on ?x ?y)") == Compound(:on, [Var(:X), Var(:Y)])
@test parse_pddl("(+ cost 1)") == Compound(:+, [Const(:cost), Const(1)])
@test parse_pddl("(= cost 0)") == Compound(:(==), [Const(:cost), Const(0)])
@test parse_pddl("(= cost 0.0)") == Compound(:(==), [Const(:cost), Const(0.0)])
@test parse_pddl("(>= cost 0)") == Compound(:(>=), [Const(:cost), Const(0)])
@test parse_pddl("(!= cost 0)") == Compound(:(!=), [Const(:cost), Const(0)])

@test parse_pddl("(and (on a b) (on b c))") ==
    Compound(:and, [pddl"(on a b)", pddl"(on b c)"])
@test parse_pddl("(or (on a b) (on b c))") ==
    Compound(:or, [pddl"(on a b)", pddl"(on b c)"])
@test parse_pddl("(not (on a b))") ==
    Compound(:not, [pddl"(on a b)"])
@test parse_pddl("(imply (on a b) (on b c))") ==
    Compound(:imply, [pddl"(on a b)", pddl"(on b c)"])
@test parse_pddl("(forall (?x) (on ?x b))") ==
    Compound(:forall, [pddl"(object ?x)", pddl"(on ?x b)"])
@test parse_pddl("(forall (?x - block) (on ?x b))") ==
    Compound(:forall, [pddl"(block ?x)", pddl"(on ?x b)"])
@test parse_pddl("(forall (?x ?y - block) (on ?x ?y))") ==
    Compound(:forall, [pddl"(and (block ?x) (block ?y))", pddl"(on ?x ?y)"])
@test parse_pddl("(forall (?x - t1 ?y - t2) (on ?x ?y))") ==
    Compound(:forall, [pddl"(and (t1 ?x) (t2 ?y))", pddl"(on ?x ?y)"])
@test parse_pddl("(exists (?x) (on ?x b))") ==
    Compound(:exists, [pddl"(object ?x)", pddl"(on ?x b)"])
@test parse_pddl("(exists (?x - block) (on ?x b))") ==
    Compound(:exists, [pddl"(block ?x)", pddl"(on ?x b)"])
@test parse_pddl("(exists (?x ?y - block) (on ?x ?y))") ==
    Compound(:exists, [pddl"(and (block ?x) (block ?y))", pddl"(on ?x ?y)"])
@test parse_pddl("(exists (?x - t1 ?y - t2) (on ?x ?y))") ==
    Compound(:exists, [pddl"(and (t1 ?x) (t2 ?y))", pddl"(on ?x ?y)"])
@test parse_pddl("(when (and (on a b) (on b c)) (on a c))") ==
    Compound(:when, [pddl"(and (on a b) (on b c))", pddl"(on a c)"])
@test parse_pddl("(> (+ a b) (* c d))") ==
    Compound(:>, [Compound(:+, [Const(:a), Const(:b)]),
                  Compound(:*, [Const(:c), Const(:d)])])

end

@testset "action parsing" begin

action = pddl"""(:action wait :effect ())"""

@test PDDL.get_name(action) == :wait
@test collect(PDDL.get_argvars(action)) == Var[]
@test collect(PDDL.get_argtypes(action)) == Symbol[]
@test PDDL.get_precond(action) == Const(true)
@test PDDL.get_effect(action) == Const(true)

action = pddl"""
(:action move
 :parameters (?a ?b)
 :precondition (and (room ?a) (room ?b) (in-room ?a))
 :effect (and (not (in-room ?a)) (in-room ?b))
)"""

@test PDDL.get_name(action) == :move
@test collect(PDDL.get_argvars(action)) == [Var(:A), Var(:B)]
@test collect(PDDL.get_argtypes(action)) == [:object, :object]
@test PDDL.get_precond(action) == pddl"(and (room ?a) (room ?b) (in-room ?a))"
@test PDDL.get_effect(action) == pddl"(and (not (in-room ?a)) (in-room ?b))"

action = pddl"""
(:action unstack
 :parameters (?x - block ?y - block)
 :precondition (and (on ?x ?y) (clear ?x))
 :effect (and (holding ?x) (clear ?y) (not (on ?x ?y)) (not (clear ?x)))
)"""

@test PDDL.get_name(action) == :unstack
@test collect(PDDL.get_argvars(action)) == [Var(:X), Var(:Y)]
@test collect(PDDL.get_argtypes(action)) == [:block, :block]
@test PDDL.get_precond(action) ==
    pddl"(and (on ?x ?y) (clear ?x))"
@test PDDL.get_effect(action) ==
    pddl"(and (holding ?x) (clear ?y) (not (on ?x ?y)) (not (clear ?x)))"

end

@testset "axiom parsing" begin

axiom = pddl"""
(:axiom (above ?x ?y)
        (or (on ?x ?y) (exists (?z) (and (on ?x ?z) (above ?z ?y)))))
"""

@test axiom.head == pddl"(above ?x ?y)"
@test axiom.body ==
    [pddl"(or (on ?x ?y) (exists (?z) (and (on ?x ?z) (above ?z ?y))))"]
    

axiom = pddl"""
(:derived (above ?x ?y)
          (or (on ?x ?y) (exists (?z) (and (on ?x ?z) (above ?z ?y)))))
"""

@test axiom.head == pddl"(above ?x ?y)"
@test axiom.body ==
    [pddl"(or (on ?x ?y) (exists (?z) (and (on ?x ?z) (above ?z ?y))))"]

end

@testset "domain parsing" begin

domain = load_domain(joinpath(@__DIR__, "domain.pddl"))

@test PDDL.get_name(domain) == :shapes

requirements = PDDL.get_requirements(domain)
@test requirements[:adl] == true
@test requirements[:typing] == true
@test requirements[:fluents] == true
@test requirements[Symbol("derived-predicates")] == true

typetree = PDDL.get_typetree(domain)
@test typetree[:object] == [:shape, :color]
@test typetree[:shape] == [:triangle, :rectangle]
@test typetree[:rectangle] == [:square]
@test typetree[:square] == []
@test typetree[:color] == []

constants = PDDL.get_constants(domain)
@test constants == [pddl"(red)", pddl"(green)", pddl"(blue)"]
constypes = PDDL.get_constypes(domain)
@test constypes[pddl"(red)"] == :color
@test constypes[pddl"(green)"] == :color
@test constypes[pddl"(blue)"] == :color

predicates = PDDL.get_predicates(domain)
@test predicates[Symbol("color-of")] ==
    PDDL.Signature(Symbol("color-of"), :boolean, [Var(:S), Var(:C)], [:shape, :color])
@test predicates[:colored] ==
    PDDL.Signature(:colored, :boolean, [Var(:S)], [:shape])

functions = PDDL.get_functions(domain)
@test functions[:size] ==
    PDDL.Signature(:size, :numeric, [Var(:S)], [:shape])

axioms = PDDL.get_axioms(domain)
@test axioms[:colored].head == pddl"(colored ?s)"
@test axioms[:colored].body == [pddl"(exists (?c - color) (color-of ?s ?c))"]

actions = PDDL.get_actions(domain)
@test :recolor in keys(actions)
@test Symbol("grow-all") in keys(actions)
@test Symbol("shrink-all") in keys(actions)

end

@testset "problem parsing" begin

problem = load_problem(joinpath(@__DIR__, "problem.pddl"))

@test PDDL.get_name(problem) == Symbol("shapes-problem")

@test PDDL.get_domain_name(problem) == :shapes

@test PDDL.get_objects(problem) == [pddl"(square1)", pddl"(triangle1)"]
@test PDDL.get_objtypes(problem) == 
    Dict{Const,Symbol}(
        pddl"(square1)" => :square,
        pddl"(triangle1)" => :triangle
    )

@test PDDL.get_init_terms(problem) == @pddl(
    "(color-of square1 red)",
    "(color-of triangle1 red)",
    "(= (size square1) 1)",
    "(= (size triangle1) 2)"
)

@test PDDL.get_goal(problem) == 
    pddl"(and (= (size square1) 3) (= (size triangle1) 1))"
@test PDDL.get_metric(problem) ==
    pddl"(minimize (size triangle1))"

end

end # parsing
