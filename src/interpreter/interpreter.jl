# Interpreter-based implementations of the PDDL.jl interface

abstract type Interpreter end
struct AbstractInterpreter <: Interpreter end

include("utils.jl")
include("diff.jl")
include("evaluate.jl")
include("transition.jl")
include("available.jl")
include("execute.jl")
include("relevant.jl")
include("regress.jl")

include("concrete/concrete.jl")
# include("abstract/abstract.jl")

satisfy(domain::GenericDomain, state::State, term::Term) =
    satisfy(ConcreteInterpreter(), domain, state, term)
satisfy(domain::GenericDomain, state::State, terms::AbstractVector{<:Term}) =
    satisfy(ConcreteInterpreter(), domain, state, term)

satisfiers(domain::GenericDomain, state::State, term::Term) =
    satisfiers(ConcreteInterpreter(), domain, state, term)
satisfiers(domain::GenericDomain, state::State, terms::AbstractVector{<:Term}) =
    satisfiers(ConcreteInterpreter(), domain, state, terms)

evaluate(domain::GenericDomain, state::State, term::Term) =
    evaluate(ConcreteInterpreter(), domain, state, term)

initstate(domain::GenericDomain, problem::Problem) =
    initstate(ConcreteInterpreter(), domain, problem)

transition(domain::GenericDomain, state::State, action::Term) =
    transition(ConcreteInterpreter(), domain, state, action)

available(domain::GenericDomain, state::State, action::Action, args) =
    available(ConcreteInterpreter(), domain, state, action, args)
available(domain::GenericDomain, state::State) =
    available(ConcreteInterpreter(), domain, state)

execute(domain::GenericDomain, state::State, action::Action, args; options...) =
    execute(ConcreteInterpreter(), domain, state, action, args; options...)

relevant(domain::GenericDomain, state::State, action::Action, args) =
    relevant(ConcreteInterpreter(), domain, state, action, args)
relevant(domain::GenericDomain, state::State) =
    relevant(ConcreteInterpreter(), domain, state)

regress(domain::GenericDomain, state::State, action::Action, args; options...) =
    regress(ConcreteInterpreter(), domain, state, action, args; options...)
