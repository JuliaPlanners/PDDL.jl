@testset "Comments including a \$ character followed by any other character" begin

path = joinpath(dirname(pathof(PDDL)), "..", "test", "comments")

problem = load_problem(joinpath(path, "comment-with-dollar-sign.pddl"))
@test problem.name == Symbol("comment-with-dollar-sign-1")

end