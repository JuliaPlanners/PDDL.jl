"PDDL action definition."
abstract type Action end

get_name(action::Action) = error("Not implemented.")

get_argvars(action::Action) = error("Not implemented.")

get_argtypes(action::Action) = error("Not implemented.")

get_precond(action::Action) = error("Not implemented.")

get_precond(action::Action, args) = error("Not implemented.")

get_precond(domain::Domain, name::Symbol) =
    get_precond(get_actions(domain)[name])

get_precond(domain::Domain, term::Term) =
    get_precond(get_actions(domain)[term.name], term.args)

get_effect(action::Action) = error("Not implemented.")

get_effect(action::Action, args) = error("Not implemented.")

get_effect(domain::Domain, name::Symbol) =
    get_effect(get_actions(domain)[name])

get_effect(domain::Domain, term::Term) =
    get_effect(get_actions(domain)[term.name], term.args)
