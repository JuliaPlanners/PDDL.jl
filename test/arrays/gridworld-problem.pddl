;; ASCII ;;
; W: wall, g: goal, s: start, .: empty
; sWg
; .W.
; ...
(define (problem gridworld-problem)
  (:domain gridworld)
  (:init
    (= walls
      (transpose (bit-mat ; transpose from column-order to row-order
        (bit-vec 0 1 0)
        (bit-vec 0 1 0)
        (bit-vec 0 0 0)
      ))
    )
    (= pos (index 1 1))
  )
  (:goal (= pos (index 1 3)))
)
