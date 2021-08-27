function transition(interpreter::Interpreter,
                    domain::Domain, state::State, action::Term; options...)
    return execute(interpreter, domain, state, action; options...)
end
