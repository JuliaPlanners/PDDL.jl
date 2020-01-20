;; Modified from IPC 2002
(define (domain zeno-travel)
(:requirements :typing :fluents)
(:types aircraft person - movable movable city - object)
(:predicates (at ?x - movable ?c - city)
             (in ?p - person ?a - aircraft))
(:functions (fuel ?a - aircraft)
            (distance ?c1 - city ?c2 - city)
            (slow-burn ?a - aircraft)
            (fast-burn ?a - aircraft)
            (capacity ?a - aircraft)
            (total-fuel-used)
            (onboard ?a - aircraft)
            (zoom-limit ?a - aircraft)
            )


(:action board
 :parameters (?p - person ?a - aircraft ?c - city)
 :precondition (and (at ?p ?c)
                 (at ?a ?c))
 :effect (and (not (at ?p ?c))
              (in ?p ?a)
              (increase (onboard ?a) 1)
              (increase total-time 1)))


(:action debark
 :parameters (?p - person ?a - aircraft ?c - city)
 :precondition (and (in ?p ?a)
                 (at ?a ?c))
 :effect (and (not (in ?p ?a))
              (at ?p ?c)
              (decrease (onboard ?a) 1)
              (increase total-time 1)))

(:action fly
 :parameters (?a - aircraft ?c1 ?c2 - city)
 :precondition (and (at ?a ?c1)
                 (>= (fuel ?a)
                         (* (distance ?c1 ?c2) (slow-burn ?a))))
 :effect (and (not (at ?a ?c1))
              (at ?a ?c2)
              (increase (total-fuel-used)
                         (* (distance ?c1 ?c2) (slow-burn ?a)))
              (decrease (fuel ?a)
                         (* (distance ?c1 ?c2) (slow-burn ?a)))
              (increase total-time 1)))

(:action zoom
 :parameters (?a - aircraft ?c1 ?c2 - city)
 :precondition (and (at ?a ?c1)
                 (>= (fuel ?a)
                         (* (distance ?c1 ?c2) (fast-burn ?a)))
                 (<= (onboard ?a) (zoom-limit ?a)))
 :effect (and (not (at ?a ?c1))
              (at ?a ?c2)
              (increase (total-fuel-used)
                         (* (distance ?c1 ?c2) (fast-burn ?a)))
              (decrease (fuel ?a)
                         (* (distance ?c1 ?c2) (fast-burn ?a)))
              (increase total-time 1)))

(:action refuel
 :parameters (?a - aircraft ?c - city)
 :precondition (and (> (capacity ?a) (fuel ?a))
               (at ?a ?c)
                )
 :effect (and (assign (fuel ?a) (capacity ?a)) (increase total-time 1))
)


)
