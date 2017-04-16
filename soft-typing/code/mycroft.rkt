#lang typed/racket/base
(require racket/match racket/list)

;; -----------------------------------------------------------------------------
;; original code

;; Mycroft, https://www.cl.cam.ac.uk/~am21/papers/icop84.pdf
;; list dlist are isomorphic data structures
; let rec f(x : structure) = case x of
;   (basecase(y): ...
;   |listcase(y): g(y, (hd, tl, null))
;   |dlistcase(y): g(y, (dhd, dtl, dnull)))
; and g(x : a, (xhd: a->b, xtl: a->a, xnull: a->bool)) =
;   if xnull(x) then () else (f(xhd x), g(xtl x, (xhd, xtl, xnull)))

;; -----------------------------------------------------------------------------

(struct (A) Basecase [[y : A]])

(define-type [Structure A] (U [Basecase A] [Listof (Structure A)] [MListof (Structure A)]))

(: f (All (A) (-> (Structure A) (Listof A))))
(define (f x)
  (cond
   [(Basecase? x)
    (list (Basecase-y x))]
   [(pair? x)
    (g x (list #{car :: (-> [Listof (Structure A)] (Structure A))}
               #{cdr :: (-> [Listof (Structure A)] [Listof (Structure A)])}
               null?))]
   [(mpair? x)
    (g x
       (list #{mcar :: (-> [MListof (Structure A)] (Structure A))}
             #{mcdr :: (-> [MListof (Structure A)] [MListof (Structure A)])}
             null?))]
   [else (error 'exhaust)]))

(: g (All (A B) (-> A (List (-> A (Structure B)) (-> A A) (-> A Boolean)) (Listof B))))
(define (g x f*)
  (match-define (list xhd xtl xnull) f*)
  (if (xnull x)
    '()
    (append (f (xhd x)) (g (xtl x) f*))))

(f (list (Basecase 1) (Basecase 2) (Basecase 3)))
