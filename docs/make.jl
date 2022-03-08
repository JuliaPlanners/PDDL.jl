using Documenter, PDDL

push!(LOAD_PATH,"../src/")

makedocs(
   sitename="PDDL.jl",
   format=Documenter.HTML(prettyurls=get(ENV, "CI", nothing) == "true"),
   pages=[
      "PDDL.jl" => "index.md",
      "Tutorials" => [
         "tutorials/getting_started.md",
         "tutorials/writing_planners.md",
         "tutorials/speeding_up.md",
         "tutorials/extending.md"
      ],
      "Reference" => [
         "ref/overview.md",
         "ref/interface.md",
         "ref/parser_writer.md",
         "ref/interpreter.md",
         "ref/compiler.md",
         "ref/absint.md",
         "ref/utilities.md"
      ]
   ]
)
