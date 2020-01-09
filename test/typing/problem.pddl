;; Gripper problem from Wikipedia article on PDDL
(define (problem gripper-problem)
    (:domain gripper-typed)
    (:objects rooma - room roomb - room
              ball1 - ball ball2 - ball
              left - gripper right - gripper)
    (:init (robbyat rooma)
           (free left)
           (free right)
           (at ball1 rooma)
           (at ball2 rooma))
    (:goal (at ball1 roomb)))
