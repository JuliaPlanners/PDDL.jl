(define (problem blocksworld-problem)
   (:domain blocksworld-axioms)
   (:objects a b c)
   (:init (ontable a) (ontable b) (ontable c))
   (:goal (and (above a c) (on b c))))
