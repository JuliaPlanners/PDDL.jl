"Type signature for a PDDL fluent (i.e. predicate or function)."
struct Signature{N}
    name::Symbol
    type::Symbol
    args::NTuple{N, Var}
    argtypes::NTuple{N, Symbol}
end

Signature(name, type, args, argtypes) =
    Signature{length(args)}(name, type, Tuple(args), Tuple(argtypes))

Signature(term::Term, argtypes, type) =
    Signature(term.name, type, term.args, argtypes)

"Returns the arity (i.e. number of arguments) of a fluent signature."
arity(::Signature{N}) where {N} = N

function Base.convert(::Type{Term}, sig::Signature{0})
    return Const(sig.name)
end

function Base.convert(::Type{Term}, sig::Signature)
    return Compound(sig.name, collect(sig.args))
end

function Base.show(io::IO, sig::Signature)
    args = ["?$(lowercase(string(a.name))) - $t"
            for (a, t) in zip(sig.args, sig.argtypes)]
    print(io, "($(join([sig.name; args], " "))) - $(sig.type)")
end
