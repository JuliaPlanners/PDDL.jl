(define (problem storytellers-problem)
  (:domain storytellers)
  (:objects
    jacob wilhelm - storyteller
    hanau steinau marburg - audience
    snowwhite rumpelstiltskin cinderella frogprince - story
  )
  (:init
    (= (story-set)
       (construct-set snowwhite rumpelstiltskin cinderella frogprince))
    (= (known jacob)
       (construct-set snowwhite rumpelstiltskin))
    (= (known wilhelm)
       (construct-set cinderella frogprince))
    (= (heard hanau)
       (construct-set rumpelstiltskin))
    (= (heard steinau)
       (construct-set cinderella))
    (= (heard marburg)
       (empty-set))
  )
  (:goal (and
      ; each audience must hear more than half of all stories
      (> (* (cardinality (heard hanau)) 2) (cardinality (story-set)))
      (> (* (cardinality (heard steinau)) 2) (cardinality (story-set)))
      (> (* (cardinality (heard marburg)) 2) (cardinality (story-set)))
      ; at least one audience must hear all stories
      (or
        (= (cardinality (heard hanau)) (cardinality (story-set)))
        (= (cardinality (heard steinau)) (cardinality (story-set)))
        (= (cardinality (heard marburg)) (cardinality (story-set)))
      )
  ))
)
