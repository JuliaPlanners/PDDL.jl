(define (domain gridworld)
    (:requirements :fluents)
    (:functions (pos) - matrix-index (walls) - bit-matrix)
    (:action up
     :precondition (and (> (get-row pos) 1)
                        (= (get-index walls (decrease-row pos 1)) false))
     :effect (assign pos (decrease-row pos 1))
    )
    (:action down
     :precondition (and (< (get-row pos) (height walls))
                        (= (get-index walls (increase-row pos 1)) false))
     :effect (assign pos (increase-row pos 1))
    )
    (:action right
     :precondition (and (< (get-col pos) (width walls))
                        (= (get-index walls (increase-col pos 1)) false))
     :effect (assign pos (increase-col pos 1))
    )
    (:action left
     :precondition (and (> (get-col pos) 1)
                        (= (get-index walls (decrease-col pos 1)) false))
     :effect (assign pos (decrease-col pos 1))
    )
)
