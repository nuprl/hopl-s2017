type 'a aList = ANil | ACons of 'a * 'a aList
and 'a dList = DNil | DCons of 'a * 'a dList
and 'a structure = Basecase of 'a | Listcase of ('a structure) aList | Dlistcase of ('a structure) dList

let hd (x : 'a aList) =
  match x with
  | ANil -> failwith "die"
  | ACons (x, y) -> x

let tl (x : 'a aList) =
  match x with
  | ANil -> failwith "die"
  | ACons (x, y) -> y

let null (x : 'a aList) =
  match x with
  | ANil -> true
  | ACons _ -> false

let dhd (x : 'a dList) =
  match x with
  | DNil -> failwith "die"
  | DCons (x, y) -> x

let dtl (x : 'a dList) =
  match x with
  | DNil -> failwith "die"
  | DCons (x, y) -> y

let dnull (x : 'a dList) =
  match x with
  | DNil -> true
  | DCons _ -> false

let rec f (x : 'a structure) =
  match x with
  | Basecase y -> y
  | Listcase y -> g y (hd, tl, null)
  | Dlistcase y -> g y (dhd, dtl, dnull)
and g (x : 'a) (xhd : 'a -> 'b) (xtl : 'a -> 'a) (xnull : 'a -> bool) =
  if xnull x
  then []
  else [ f (xhd x); g (xtl x) (xhd, xtl, xnull) ]


