## Convert expressions back to strings
unparse(expr) = string(expr)
unparse(expr::Vector) = "(" * join(unparse.(expr), " ") * ")"
unparse(expr::Var) = "?" * lowercase(string(expr.name))
unparse(expr::Keyword) = ":" * string(expr.name)
