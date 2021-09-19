(define (domain storytellers)
  (:requirements :typing :fluents)
  (:types storyteller audience story)
  (:functions (known ?t - storyteller) - set
              (heard ?a - audience) - set
              (story-set) - set
  )
  (:action entertain
    :parameters (?t - storyteller ?a - audience)
    :precondition (true)
    :effect ((assign (heard ?a) (union (heard ?a) (known ?t))))
  )
)
