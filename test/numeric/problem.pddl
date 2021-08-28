(define (problem zeno-travel-problem)
(:domain zeno-travel)
(:objects
	plane1 - aircraft
	person1 - person
	person2 - person
	city0 - city
	city1 - city
	city2 - city
	)
(:init
	(at plane1 city0)
	(= (capacity plane1) 10232)
	(= (fuel plane1) 3956)
	(= (slow-burn plane1) 4)
	(= (fast-burn plane1) 15)
	(= (onboard plane1) 0)
	(= (zoom-limit plane1) 8)
	(at person1 city0)
	(at person2 city2)
	(= (distance city0 city0) 0)
	(= (distance city0 city1) 678)
	(= (distance city0 city2) 775)
	(= (distance city1 city0) 678)
	(= (distance city1 city1) 0)
	(= (distance city1 city2) 810)
	(= (distance city2 city0) 775)
	(= (distance city2 city1) 810)
	(= (distance city2 city2) 0)
	(= (total-fuel-used) 0)
	(= (total-time) 0)
)
(:goal (and
	(at plane1 city1)
	(at person1 city2)
	(at person2 city0)
	)
)
(:metric minimize (+ (* 4 (total-time))  (* 5 (total-fuel-used))))
)
