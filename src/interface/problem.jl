"PDDL planning problem."
abstract type Problem end

get_objects(problem::Problem) = error("Not implemented.")

get_objtypes(problem::Problem) = error("Not implemented.")

get_goal(problem::Problem) = error("Not implemented.")

get_metric(problem::Problem) = error("Not implemented.")
