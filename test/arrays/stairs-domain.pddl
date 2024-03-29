(define (domain stairs)
    (:requirements :fluents)
    (:functions (xpos) - integer (zpos) - numeric (stairs) - num-vector)
    (:action climb-up
     :precondition (and (< xpos (length stairs))
                        (<= (get-index stairs (+ xpos 1)) (+ zpos 1)))
     :effect (and (increase xpos 1)
                  (assign zpos (get-index stairs (+ xpos 1))))
    )
    (:action climb-down
     :precondition (and (> xpos 1)
                        (>= (get-index stairs (- xpos 1)) (- zpos 1)))
     :effect (and (decrease xpos 1)
                  (assign zpos (get-index stairs (- xpos 1))))
    )
    (:action jump-up
     :precondition (and (< xpos (length stairs))
                        (<= (get-index stairs (+ xpos 1)) (+ zpos 3)))
     :effect (and (increase xpos 1)
                  (assign zpos (get-index stairs (+ xpos 1))))
    )
    (:action jump-down
     :precondition (and (> xpos 1)
                        (>= (get-index stairs (- xpos 1)) (- zpos 3)))
     :effect (and (decrease xpos 1)
                  (assign zpos (get-index stairs (- xpos 1))))
    )
)
