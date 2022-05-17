(define (domain gridworld)
    (:requirements :fluents)
    (:functions (xpos) (ypos) - integer (walls) - bit-matrix)
    (:action up
     :precondition (and (> ypos 1)
                        (= (get-index walls (- ypos 1) xpos) false))
     :effect (decrease ypos 1)
    )
    (:action down
     :precondition (and (< ypos (height walls))
                        (= (get-index walls (+ ypos 1) xpos) false))
     :effect (increase ypos 1)
    )
    (:action right
     :precondition (and (< xpos (width walls))
                        (= (get-index walls ypos (+ xpos 1)) false))
     :effect (increase xpos 1)
    )
    (:action left
     :precondition (and (> xpos 1)
                        (= (get-index walls ypos (- xpos 1)) false))
     :effect (decrease xpos 1)
    )
)
