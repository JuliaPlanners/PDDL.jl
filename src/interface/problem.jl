"PDDL planning problem."
abstract type Problem end

get_objects(::Problem) = error("Not implemented.")

get_objtypes(::Problem) = error("Not implemented.")

get_goal(::Problem) = error("Not implemented.")

get_metric(::Problem) = error("Not implemented.")
