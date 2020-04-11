# Functions for preprocessing PDDL constructs into canonical forms

"Preprocess domain by instantiating and regularizing logical formulae."
function preprocess(domain::Domain, problem::Union{Problem,Nothing}=nothing;
                    options...)
    domain = copy(domain)
    # Get object type declarations
    objtypes = get(options, :objtypes, nothing)
    if problem != nothing && objtypes == nothing
        objtypes = get_objtype_clauses(problem)
    end
    # Unpack flags
    regularize = get(options, :regularize, true)
    instantiate = get(options, :instantiate, objtypes != nothing)
    # Remove universal quantifiers in axioms
    if instantiate && objtypes != nothing
        domain.axioms = [deuniversalize(ax, objtypes) for ax in domain.axioms]
    end
    # Regularize all axiom bodies to conjunctions of literals
    if regularize
        domain.axioms = regularize_clauses(domain.axioms)
    end
    # Preprocess action and event definitions
    domain.actions = Dict{Symbol,Action}(
        k => preprocess(v, objtypes; options...) for (k, v) in domain.actions)
    domain.events = [preprocess(e, objtypes; options...) for e in domain.events]
    return domain
end

function preprocess(act::Action, objtypes=nothing; options...)
    regularize = get(options, :regularize, true)
    instantiate = get(options, :instantiate, objtypes != nothing)
    precond, effect = act.precond, act.effect
    if instantiate && objtypes != nothing
        precond = deuniversalize(precond, objtypes)
        effect = deuniversalize(effect, objtypes)
    end
    if regularize
        precond = to_dnf(precond)
    end
    return Action(act.name, act.args, act.types, precond, effect)
end

function preprocess(event::Event, objtypes=nothing; options...)
    regularize = get(options, :regularize, true)
    instantiate = get(options, :instantiate, objtypes != nothing)
    precond, effect = event.precond, event.effect
    if instantiate && objtypes != nothing
        precond = deuniversalize(precond, objtypes)
        effect = deuniversalize(effect, objtypes)
    end
    if regularize
        precond = to_dnf(precond)
    end
    return Event(event.name, precond, effect)
end
