
 - [Talk outline](index.md)

## Simple model of Monitors

Start from λ-ISWIM. Keyword `sync` inspired by the "synchronized" of Java.

Key properties:

 - only one process can be in the monitor at once
 - read/write of monitor-private state can only be done when in the monitor
 - `await` blocks until some other thread does a `signal`, which triggers all waiters
 - nondeterministic scheduling

### Syntax

    Expressions  e := ... | fork e | ref e | e←e | !e | sync e e | sync ℓ→(v,q) e | await | signal | ℓ
    Values     v,w := ... | ℓ

    Proc. tab. p,q := e | q|q
    Stores       σ := · | ℓ→(v,q) | σ;σ
    Machines     M := <q # σ>

    Expr ctxt    E := ... | ref E | E←e | ℓ←E | !E | sync E e | sync ℓ→(v,q) E

Programs are those `e` that are closed and mention neither any `ℓ` nor
any use of `sync ℓ→(v,q) e`.

Given a program `e`, the starting machine state is just `<e # ·>`.

### Structural Equivalence

Structural equivalence `≡` over machines includes:

 - Par operator `|` associative, commutative, zero any element of `v`
 - Store adjoin operator `;` associative, commutative, distinguished zero `·`

### Reductions

Read the following reduction rules as quotiented by `≡`.

    base    e ↪ e'  ⇒  <p|E[e] # σ> → <p|E[e'] # σ>

    fork    <p|E[fork e] # σ> → <p|E[0]|e # σ>

    ref     <p|E[ref v] # σ> → <p|E[ℓ] # σ;ℓ→(v,·)>    where ℓ fresh

    lock    <p|E[sync ℓ e] # σ;ℓ→(v,q)> → <p|E[sync ℓ→(v,q) e] # σ>
    unlock  <p|E[sync ℓ→(v,q) w] # σ> → <p|E[w] # σ;ℓ→(v,q)>

    await   <p|E[sync ℓ→(v,q) E'[await]] # σ> → <p # σ;ℓ→(v,q)|E[sync ℓ E'[0]]>
    signal  <p|E[sync ℓ→(v,q) E'[signal]] # σ> → <p|E[sync ℓ→(v,·) E'[0]]|q # σ>

    write   <p|E[sync ℓ→(v,q) E'[ℓ←w]] # σ> → <p|E[sync ℓ→(w,q) E'[ℓ]] # σ>
    read    <p|E[sync ℓ→(v,q) E'[!ℓ]] # σ> → <p|E[sync ℓ→(w,q) E'[v]] # σ>

    nest    <p|E[sync ℓ→(v,q) E'[sync ℓ e]] # σ> → <p|E[sync ℓ→(v,q) E'[e]] # σ>

### Examples

Are these correct? Are they easy to understand?

One-place buffer:

    NEW() := ref NONE

    GET(b) := sync b (rec retry() . match !b
                                      NONE -> await; retry()
                                      SOME v -> b←NONE; signal; v)

    PUT(b,v) := sync b (rec retry() . match !b
                                        NONE -> b←(SOME v); signal
                                        SOME w -> await; retry())

Note doesn't preserve ordering of requests!

Zero-place buffer (synchronous channel):

    data STATE α = R | N | W α

    NEW() := ref N

    GET(c) := sync c (rec retry(). match !c
                                     R -> await; retry()
                                     N -> c←R; signal; retry()
                                     W v -> c←N; signal; v)

    PUT(c,v) := sync c (rec retry() . match !c
                                        R -> c←(W v); signal
                                        N -> await; retry()
                                        W _ -> await; retry())

Note doesn't preserve ordering of requests!

Queue (asynchronous channel):

    NEW() := ref []

    GET(c) := sync c (rec retry(). match !c
                                     [] -> await; retry()
                                     v:vs -> c←vs; v)

    PUT(c,v): sync c (c←(!c ++ [v]); signal)

Notice that this does *not* preserve ordering of `GET` requests, but
*does* preserve ordering of `PUT`s!

Chat room:

    NEW() := ref {}

    CONNECT(r, user, callback) :=
      sync r
        for u in (!r).keys: callback(u + " arrived")
        r ← (!r){user ⟼ callback}
        ANNOUNCE(r, user + " arrived")

    DISCONNECT(r, user) :=
      sync r
        if user in (!r).keys
          r ← (!r) \ user
          ANNOUNCE(r, user + " left")

    SPEAK(r, user, text) :=
      sync r
        ANNOUNCE(!r, user + " says '" + text + "'")

    ANNOUNCE(r, what) :=
      for (user, callback) in !r
        try { callback(what) }
        catch { DISCONNECT(r, user) }

### Next Steps

We can easily extend this little language with `signalOne`, which
awakens *at least one* waiter (if there are any at all). Q1: Why not
*exactly* one waiter (if any exist)? Q2: Why is it not harmful for
`signalOne` to wake up potentially more than one waiter?

Another variation includes `await e`, where the `e` is a *predicate*
which must be satisfied before execution moves on from the `await`.
Roughly speaking,

    await e ≡ while (not e) { await }

The advantage of the special syntax is that the compiler can offer
special support, implementing it more efficiently for special cases of
`e`.

How can we wait for some condition to obtain within one monitor *or*
another? Composition of `await` doesn't work. The idea of *Software
Transactional Memory* (STM), with its nifty `orElse` construct, is an
interesting next step.
