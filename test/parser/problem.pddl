; Problem with most supported PDDL syntax $0-9a-zA-Z!@#$%^&*()_+-=[]{}|;:'"
(define (problem shapes-problem)
  (:domain shapes)
  ; Objects
  (:objects square1 - square triangle1 - triangle)  
  ; Initial state
  (:init (color-of square1 red)
         (color-of triangle1 red)
         (= (size square1) 1)
         (= (size triangle1) 2))
  ; Goal specification
  (:goal (and (= (size square1) 3)
              (= (size triangle1) 1)))
  ; Metric specification
  (:metric minimize (size triangle1))
)
