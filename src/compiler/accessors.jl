
function generate_get_expr(domain::Domain, state::State, term::Const,
                           varmap=Dict{Var,Any}(), state_var=:state)
    return :($state_var.$(term.name))
end

function generate_get_expr(domain::Domain, state::State, term::Var,
                           varmap=Dict{Var,Any}(), state_var=:state)
    return :($(varmap[term]))
end

function generate_get_expr(domain::Domain, state::State, term::Compound,
                           varmap=Dict{Var,Any}(), state_var=:state)
    indices = generate_fluent_ids(domain, state, term,
                                  get_fluent(domain, term.name), varmap)
    return :($state_var.$(term.name)[$(indices...)])
end

function generate_set_expr(domain::Domain, state::State, term::Const,
                           val, varmap=Dict{Var,Any}(), state_var=:state)
    if domain isa AbstractedDomain && domain.interpreter.autowiden
        prev_val = generate_get_expr(domain, state, term, varmap, :prev_state)
        return :(setfield!($state_var, $(QuoteNode(term.name)), widen($prev_val, $val)))
    else
        return :(setfield!($state_var, $(QuoteNode(term.name)), $val))
    end
end

function generate_set_expr(domain::Domain, state::State, term::Compound,
                           val, varmap=Dict{Var,Any}(), state_var=:state)
    indices = generate_fluent_ids(domain, state, term,
                                  get_fluent(domain, term.name), varmap)
    if domain isa AbstractedDomain && domain.interpreter.autowiden
        prev_val = generate_get_expr(domain, state, term, varmap, :prev_state)
        return :($state_var.$(term.name)[$(indices...)] = widen($prev_val, $val))
    else
        return :($state_var.$(term.name)[$(indices...)] = $val)
    end
end

function generate_fluent_ids(domain::Domain, state::State, term::Term,
                             sig::Signature, varmap=Dict{Var,Any}(),
                             state_var=:state)
    if get_requirements(domain)[:typing]
        ids = map(zip(term.args, sig.argtypes)) do (arg, type)
            if arg isa Var
                :(objectindex($state_var, $(QuoteNode(type)), $(varmap[arg])))
            else
                objects = sort(get_objects(domain, state, type), by=x->x.name)
                findfirst(isequal(arg), objects)
            end
        end
    else
        objects = sort(collect(get_objects(state)), by=x->x.name)
        ids = map(term.args) do arg
            if arg isa Var
                :(objectindex($state_var, $(varmap[arg])))
            else
                findfirst(isequal(arg), objects)
            end
        end
    end
    return ids
end

function generate_fluent_dims(domain::Domain, state::State, pred::Signature)
    if get_requirements(domain)[:typing]
        dims = [length(get_objects(domain, state, ty)) for ty in pred.argtypes]
    else
        dims = fill(length(get_objects(state)), length(pred.args))
    end
    return dims
end
