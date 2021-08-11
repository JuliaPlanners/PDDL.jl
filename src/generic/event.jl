"PDDL event description."
struct GenericEvent <: Event
    name::Symbol # Name of event
    precond::Term # Precondition / trigger of event
    effect::Term # Effect of event
end

Base.:(==)(e1::GenericEvent, e2::GenericEvent) = (e1.name == e2.name &&
    e1.precond == e2.precond && e1.effect == e2.effect)
