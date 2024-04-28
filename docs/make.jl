using Documenter, PDDL

makedocs(
   sitename="PDDL.jl",
   format=Documenter.HTML(
      prettyurls=get(ENV, "CI", nothing) == "true",
      canonical="https://juliaplanners.github.io/PDDL.jl/stable",
      description="Documentation for the PDDL.jl automated planning library.",
      assets = ["assets/logo.ico"],
      highlights=["lisp"] # Use Lisp highlighting as PDDL substitute
   ),
   pages=[
      "PDDL.jl" => "index.md",
      "Tutorials" => [
         "tutorials/getting_started.md",
         "tutorials/writing_planners.md",
         "tutorials/speeding_up.md"
      ],
      "Reference" => [
         "ref/overview.md",
         "ref/datatypes.md",
         "ref/interface.md",
         "ref/parser_writer.md",
         "ref/interpreter.md",
         "ref/compiler.md",
         "ref/absint.md",
         "ref/extensions.md",
         "ref/utilities.md"
      ]
   ]
)

deploydocs(
    repo = "github.com/JuliaPlanners/PDDL.jl.git",
)
