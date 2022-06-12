; Source : Thiebaux et al, 2005; DOI : 10.1016/j.artint.2005.05.004
(define (domain blocksworld-axioms)
  (:requirements :strips :derived-predicates)
  (:predicates (ontable ?x) (on ?x ?y) ; basic
               (holding ?x) (above ?x ?y) (clear ?x) (handempty)) ; derived
  (:derived (holding ?x)
            (and (not (ontable ?x))(not (exists (?y) (on ?x ?y)))))
  (:derived (above ?x ?y)
            (or (on ?x ?y) (exists (?z) (and (on ?x ?z) (above ?z ?y)))))
  (:derived (clear ?x)
            (and (not (holding ?x)) (not (exists (?y) (on ?y ?x)))))
  (:derived (handempty)
            (forall (?x) (not (holding ?x))))
  (:action pickup
   :parameters (?x)
   :precondition (and (clear ?x) (ontable ?x) (handempty))
   :effect (not (ontable ?x)))
  (:action putdown
   :parameters (?x)
   :precondition (holding ?x)
   :effect (ontable ?x))
  (:action stack
   :parameters (?x ?y)
   :precondition (and (clear ?y) (holding ?x))
   :effect (on ?x ?y))
  (:action unstack
   :parameters (?x ?y)
   :precondition (and (on ?x ?y) (clear ?x) (handempty))
   :effect (not (on ?x ?y)))
)
