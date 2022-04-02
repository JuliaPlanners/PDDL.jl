using Documenter, PDDL

# Include workaround to inject custom meta tags
include("metatags.jl")

# Add custom metatags
empty!(CUSTOM_META_TAGS)
PREVIEW_IMAGE_URL =
   "https://juliaplanners.github.io/PDDL.jl/dev/assets/preview-image.png"
SITE_DESCRIPTION = "Documentation for the PDDl.jl automated planning library."
append!(CUSTOM_META_TAGS, [
   meta[:property => "description", :content => SITE_DESCRIPTION],
   # OpenGraph tags
   meta[:property => "og:type", :content => "website"],
   meta[:property => "og:image", :content => PREVIEW_IMAGE_URL],
   meta[:property => "og:description", :content => SITE_DESCRIPTION],
   # Twitter tags
   meta[:property => "twitter:card", :content => "summary_large_image"],
   meta[:property => "twitter:image", :content => PREVIEW_IMAGE_URL],
   meta[:property => "twitter:description", :content => SITE_DESCRIPTION],
])

makedocs(
   sitename="PDDL.jl",
   format=Documenter.HTML(
      prettyurls=get(ENV, "CI", nothing) == "true",
      highlights=["lisp"] # Use Lisp highlighting as PDDL substitute
   ),
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
         "ref/datatypes.md",
         "ref/interface.md",
         "ref/parser_writer.md",
         "ref/interpreter.md",
         "ref/compiler.md",
         "ref/absint.md",
         "ref/utilities.md"
      ]
   ]
)

deploydocs(
    repo = "github.com/JuliaPlanners/PDDL.jl.git",
)
