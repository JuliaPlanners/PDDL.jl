"PDDL action definition."
abstract type Action end

get_name(::Action) = error("Not implemented.")

get_argvars(::Action) = error("Not implemented.")

get_argtypes(::Action) = error("Not implemented.")

get_precond(::Action) = error("Not implemented.")

get_precond(::Action, args) = error("Not implemented.")

get_effect(::Action) = error("Not implemented.")

get_effect(::Action, args) = error("Not implemented.")
