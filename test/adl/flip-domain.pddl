;; Grid flipping domain with conditional effects and foralls
(define (domain flip)
  (:requirements :adl :typing)
  (:types row column)
  (:predicates (white ?r - row ?c - column))
  (:action flip_row
    :parameters (?r - row)
    :effect (forall (?c - column)
	      						(and (when (white ?r ?c) (not (white ?r ?c)))
		   									 (when (not (white ?r ?c)) (white ?r ?c))))
  )
  (:action flip_column
    :parameters (?c - column)
    :effect (forall (?r - row)
	      						(and (when (white ?r ?c) (not (white ?r ?c)))
		   					 				 (when (not (white ?r ?c)) (white ?r ?c))))
  )
)
