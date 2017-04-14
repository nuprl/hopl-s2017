#lang typed/racket/base

;; Does not typecheck in TR
;; Need to contrain `A` in the body of `Treeof A`
;;
;; "Generally a type variable naked in a union is just not going to do what
;;  you want. There's no way to keep it disjoint from the other types in the
;;  union." --ianj
;;
;; "... pass in a predicate for A ..." --ntoronto

;; See also: https://groups.google.com/d/msg/racket-users/9SZWZ-6iDak/CtmF32STnpQJ

;; -----------------------------------------------------------------------------

(define-type (Treeof A) (U Null A (Pairof (Treeof A) (Treeof A))))

(: flatten (All (A) (-> (Treeof A) (Listof A))))
(define (flatten l)
  (cond
   [(null? l) '()]
   [(pair? l) (append (#{flatten @ A} (car l)) (#{flatten @ A} (cdr l)))]
   [else (list l)]))

(flatten '(1 (2) 3))

