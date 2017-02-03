
 - [Talk outline](index.html)

## Simple model of Tuplespaces

Start from λ-ISWIM.

Key properties:

 - roughly equivalent to the original Linda primitives, given that  
   `exec e ≈ spawn (out e)`
 - nondeterministic scheduling, because of the quotienting by `≡`

### Syntax

    Expressions e := ... | spawn e | out e | in p | rd p

    Values  u,v,w := a | (v,v)
    Patterns    p := a | (p,p) | ★ | x
    Atoms     a,b := ...

    Machines    M := <e̅,v̅>

    Expr ctxt   E := ... | out E

Programs are those `e` that are closed.

Atoms `a` are disjoint from variables `x`; I will rely on a convention
of atoms beginning with a `Capital` `Letter`, while variables will be
in `lowercase`.

Substitution descends into patterns, since they can contain variables
`x`.

The starting configuration for a program `e` is `<e,·>`

### Structural Equivalence

Structural equivalence `≡` over machines includes:

 - arbitrary permutation of the sequences in both registers of a given `M`.

### Metafunctions

To be read as an *ordered* sequence of clauses.

    match(★,v) = true
    match(a,a) = true
    match(a,b) = false
    match((p1,p2),(v1,v2)) = match(p1,v1) ∧ match(p2,v2)
    match(p,v) = false

### Reductions

Read the following reduction rules as quotiented by `≡`.

    base    e ↪ e'  ⇒  <e̅ E[e], v̅> → <e̅ E[e'], v̅>
    spawn   <e̅ E[spawn e],  v̅> → <e̅ E[0] e,  v̅>
    out     <e̅ E[out u]  ,  v̅> → <e̅ E[0]  , uv̅>
    in      <e̅ E[in p]   , uv̅> → <e̅ E[u]  ,  v̅>    when match(p,u)
    rd      <e̅ E[rd p]   , uv̅> → <e̅ E[u]  , uv̅>    when match(p,u)

### Examples

Are these correct? Are they easy to understand?

One-place buffer:

    NEW() := let b = gensym() in
             out(Empty,b);
             b

    GET(b) := match in(Full,b,★)
                (Full,_,v) -> v; out(Empty,b)

    PUT(b,v) := in(Empty,b); out(Full,b,v)

Note doesn't preserve ordering of requests!

Zero-place buffer (synchronous channel):

    NEW() := let c = gensym() in
             spawn (rec mainloop() .
                      in(R,c);
                      match in(W,c,★)
                        in(W,c,v) ->
                          out(AR,c,v);
                          out(AW,c,v);
                          mainloop());
             c

    GET(c) := out(R,c); match in(AR,c,★)
                          (AR,_,v) -> v

    PUT(c,v) := out(W,c,v); in(AW,c,v)

Note doesn't preserve ordering of requests!

Zero-place buffer, simpler this time:

    NEW() := gensym()

    GET(c) := out(R,c); match in(W,c,★)
                          (W,c,v) -> v

    PUT(c,v) := in(R,c); out(W,c,v)

Note doesn't preserve ordering of requests!

Queue (asynchronous channel):

    NEW() := let c = gensym() in
             out(Q,c,0,[]);
             spawn (while true
                      in(R,c);
                      match in(Q,c,★,★)
                        (Q,c,n,[]) -> out(Q,c,n+1,[])
                        (Q,c,n,v:vs) -> out(Q,c,n,vs); out(AR,c,v));
             spawn (while true
                      in(W,c,v);
                      match in(Q,c,★,★)
                        (Q,c,0,vs) -> out(Q,c,0,v:vs)
                        (Q,c,n,[]) -> out(Q,c,n-1,[]); out(AR,c,v)
                        (Q,c,n,w:vs) -> out(Q,c,n-1,vs ++ [v]); out(AR,c,w));
             c

    GET(c) := out(R,c); match in(AR,c,★)
                          (A,_,v) -> v

    PUT(c,v) := out(W,c,v)

Notice that this does *not* preserve ordering of `GET` requests, but
*does* preserve ordering of `PUT`s!

Queue, simpler this time:

    NEW := let c = gensym() in
           out(Q,c,False,[]);
           c

    GET(c) := match in(Q,c,True,★)
                in(Q,c,True,[m]) -> out(Q,c,False,[]); m
                in(Q,c,True,m:ms) -> out(Q,c,True,ms); m

    PUT(c,v) := match in(Q,c,★,★)
                  in(Q,c,_,ms) -> out(Q,c,True,ms++[v])

Notice that this does *not* preserve ordering of `GET` requests, but
*does* preserve ordering of `PUT`s!

Chat room: this is difficult to implement directly with the primitives
on offer; easier to encode in terms of (the encoding of) synchronous
channels. Inefficient!

### Next Steps

No reactions. No cleanup if a process crashes.

Add expressions `ing p` and `rdg p`, with these rules:

    ing     <e̅ E[ing p], v̅> → <e̅ E[ {w | w∈v̅,match(p,w)} ], {u | u∈v̅,¬match(p,u)} >
    rdg     <e̅ E[rdg p], v̅> → <e̅ E[ {w | w∈v̅,match(p,w)} ], v̅>
