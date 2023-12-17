; Domain with most supported PDDL syntax $0-9a-zA-Z!@#$%^&*()_+-=[]{}|;:'",./<>?
(define (domain shapes)
  ; PDDL requirements
  (:requirements :adl :typing :fluents :derived-predicates)
  ; PDDL types
  (:types
    square - rectangle
    triangle rectangle - shape
    shape color - object
  )
  ; PDDL constants
  (:constants red green blue - color)
  ; PDDL predicates
  (:predicates (color-of ?s - shape ?c - color) (colored ?s - shape))
  ; PDDL functions
  (:functions (size ?s - shape) - numeric)
  ; PDDL axioms
  (:derived (colored ?s) (exists (?c - color) (color-of ?s ?c)))
  ; PDDL actions
  (:action recolor
   :parameters (?s - shape ?c1 - color ?c2 - color)
   :precondition (and (color-of ?s ?c1))
   :effect (and (not (color-of ?s ?c1)) (color-of ?s ?c2))
  )
  (:action grow-all
   :parameters (?c - color)
   :effect (forall (?s - shape)
                   (when (color-of ?s ?c) (increase (size ?s) 1)))
  )
  (:action shrink-all
   :parameters (?c - color)
   :effect (forall (?s - shape)
                   (when (color-of ?s ?c) (decrease (size ?s) 1)))
  )
)
