; Source : Thiebaux et al, 2005; DOI : 10.1016/j.artint.2005.05.004
(define (domain blocksworld-axioms)
  (:requirements :strips :quantified-preconditions)
  (:predicates (on-table ?x) (on ?x ?y) ; basic
               (holding ?x) (above ?x ?y) (clear ?x) (handempty)) ; derived
  (:derived (holding ?x)
            (and (not (on-table ?x))(not (exists (?y) (on ?x ?y)))))
  (:derived (above ?x ?y)
            (or (on ?x ?y) (exists (?z) (and (on ?x ?z) (above ?z ?y)))))
  (:derived (clear ?x)
            (and (not (holding ?x)) (not (exists (?y) (on ?y ?x)))))
  (:derived (handempty)
            (forall (?x) (not (holding ?x))))
  (:action pickup
   :parameters (?ob)
   :precondition (and (clear ?ob) (on-table ?ob) (handempty))
   :effect (not (on-table ?ob)))
  (:action putdown
   :parameters (?ob)
   :precondition (holding ?ob)
   :effect (on-table ?ob))
  (:action stack
   :parameters (?ob ?underob)
   :precondition (and (clear ?underob) (holding ?ob))
   :effect (on ?ob ?underob))
  (:action unstack
   :parameters (?ob ?underob)
   :precondition (and (on ?ob ?underob) (clear ?ob) (handempty))
   :effect (not (on ?ob ?underob)))
)
