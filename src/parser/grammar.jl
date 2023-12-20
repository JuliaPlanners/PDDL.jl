## Parser combinator from strings to Julia expressions
# Adapted from LispSyntax.jl (https://github.com/swadey/LispSyntax.jl)

"Parser combinator for PDDL Lisp syntax."
lisp         = Delayed()

white_space  = p"(([\s\n\r]*(?<!\\);[^\n\r]+[\n\r\s]*)+|[\s\n\r]+)"
opt_ws       = white_space | e""

doubley      = p"[-+]?[0-9]*\.[0-9]+([eE][-+]?[0-9]+)?" > (x -> parse(Float64, x))
floaty_dot   = p"[-+]?[0-9]*\.[0-9]+([eE][-+]?[0-9]+)?[Ff]" > (x -> parse(Float32, x[1:end-1]))
floaty_nodot = p"[-+]?[0-9]*[0-9]+([eE][-+]?[0-9]+)?[Ff]" > (x -> parse(Float32, x[1:end-1]))
floaty       = Alt!(floaty_dot, floaty_nodot)
inty         = p"[-+]?\d+" > (x -> parse(Int, x))

booly        = p"(true|false)" > (x -> x == "true" ? true : false)
stringy      = p"(?<!\\)\".*?(?<!\\)\"" > (x -> convert(String, x[2:end-1]))

keywordy     = E":" + p"[\w_][\w_\-]*" > (x -> Keyword(lowercase(x)))
vary         = E"?" + p"[\w_][\w_\-]*" > (x -> Var(Symbol(uppercasefirst(lowercase(x)))))
symboly      = p"[\w_][\w_\-]*" > (x -> Symbol(lowercase(x)))
opsymy       = p"[^\d():\?{}'`,;~\[\]\s\w$]+" > Symbol

insymy       = E"$" + p"[\w_]+" > (x -> esc(Symbol(x)))
inopeny      = Seq!(E"${", ~opt_ws)
inclosey     = Alt!(E"}", Error("expected closing brace"))
inexpr       = Seq!(~inopeny, p"[^{}]+", ~inclosey) > (x -> esc(Meta.parse(x)))

openy        = Seq!(E"(", ~opt_ws)
closey       = Alt!(E")", Error("invalid expression"))
sexpr        = Seq!(~openy, Repeat(lisp + ~opt_ws; backtrack=false), ~closey) |> (x -> x)

lisp.matcher = Alt!(floaty, doubley, inty, booly, stringy,
                    keywordy, vary, symboly, opsymy,
                    insymy, inexpr, sexpr)

const top_level = Seq!(Repeat(~opt_ws + lisp; backtrack=false), ~opt_ws, Eos())

function parse_string(str::AbstractString)
    try
        return parse_one(str, top_level)[1]
    catch e
        error(e.msg)
    end
end
