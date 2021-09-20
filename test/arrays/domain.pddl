(define (domain gridworld)
    (:requirements :fluents)
    (:functions (xpos) (ypos) - integer (wallgrid) - bit-matrix)
    (:action down
     :precondition (and (< ypos (height wallgrid))
                        (= (get-index wallgrid (+ ypos 1) xpos) false))
     :effect (increase ypos 1)
    )
    (:action up
     :precondition (and (> ypos 1)
                        (= (get-index wallgrid (- ypos 1) xpos) false))
     :effect (decrease ypos 1)
    )
    (:action right
     :precondition (and (< xpos (width wallgrid))
                        (= (get-index wallgrid ypos (+ xpos 1)) false))
     :effect (increase xpos 1)
    )
    (:action left
     :precondition (and (> xpos 1)
                        (= (get-index wallgrid ypos (- xpos 1)) false))
     :effect (decrease xpos 1)
    )
)
