(define (problem stairs-problem)
  (:domain stairs)
  (:init
    (= stairs (num-vec 1 3 4 5 7))
    (= xpos 1) (= zpos 1)
  )
  (:goal (= xpos 5))
)
