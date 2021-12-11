transition(domain::GroundDomain, state::State, action::Term; options...) =
    execute(domain, state, action; options...)
transition!(domain::GroundDomain, state::State, action::Term; options...) =
    execute!(domain, state, action; options...)
