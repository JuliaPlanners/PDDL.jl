;; ASCII ;;
; W: wall, g: goal, s: start, .: empty
; sWg
; .W.
; .D.
(define (problem gridworld-problem)
  (:domain gridworld)
  (:init
    (= wallgrid (new-bit-matrix false 3 3))
    (= wallgrid (set-index wallgrid true 1 2))
    (= wallgrid (set-index wallgrid true 2 2))
    (= xpos 1) (= ypos 1)
  )
  (:goal (and (= xpos 3) (= ypos 1)))
)
