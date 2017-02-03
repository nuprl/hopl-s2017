
 - [Talk outline](index.html)

## Simple model of Channels

Start from λ-ISWIM.

Key properties:

 - synchronous reads from *and* writes to channels
 - no shared memory here; reference cells can be added orthogonally
 - mixed choice between I/O actions
 - nondeterministic scheduling, because of the quotienting by `≡`

### Syntax

    Expressions e := ... | fork e | newChan | Σ(α.e) | ℓ
    Values    v,w := ... | ℓ

    Actions     α := e<e> | e(x)
    Ready act.  r := ℓ<v> | ℓ(x)

    Machines    M := e | M|M

    Expr ctxt   E := ... | Σ(r.e)+A.e+Σ(α.e)
    Act. ctxt   A := E<e> | ℓ<E> | E(x)

Programs are those `e` that are closed and do not mention any `ℓ`.

### Structural Equivalence

Structural equivalence `≡` over machines includes:

 - Par operator `|` associative, commutative, zero any element of `v`.
 - Sum operator `+` associative, commutative, distinct zero element denoted `0`.

### Reductions

Read the following reduction rules as quotiented by `≡`.

    base    e ↪ e'  ⇒  ... | E[e]  →  ... | E[e']

    fork    ... | E[fork e]  →  ... | E[0] | e

    new     ... | E[newChan]  →  ... | E[ℓ]    where ℓ fresh

    comm    ... | E[...+ℓ<v>.e+...] | E'[...+ℓ(x).e'+...]  →  ... | E[e] | E'[e'{v/x}]

### Examples

Are these correct? Are they easy to understand?

One-place buffer:

    NEW() := let g = newChan in
             let p = newChan in
             fork (rec relay() . p(v).g<v>.relay());
             (g,p)

    GET((g,p)) := g(x).x

    PUT((g,p),v) := p<v>.0

Note doesn't preserve ordering of requests!

Zero-place buffer (synchronous channel): immediate!

Note doesn't preserve ordering of requests!

Queue (asynchronous channel):

    NEW() := let g = newChan in
             let p = newChan in
             fork relay([])
               where relay([]) = p(v).relay([v])
                     relay((m : messages)) =
                         p(v). relay((m : messages) ++ [v])
                       + g<m>. relay(messages)

    GET((g,p)) := g(x).x

    PUT((g,p),v) := p<v>.0

Note doesn't preserve ordering of requests!

Chat room:

    data Command = Connect(user, callbackCh)
                 | Disconnect(user)
                 | Speak(user, text)

    CHATROOM() := let ch = newChan in
                  fork MAINLOOP(ch,{});
                  ch

    MAINLOOP(ch,members) :=
      ch(cmd) . match cmd
                  Connect(user, callbackCh) ->
                    for peer in members.keys: callbackCh<peer + " arrived">.0
                    let m = members{user ⟼ callbackCh} in
                    ANNOUNCE(m, user + " arrived");
                    MAINLOOP(ch,m)
                  Disconnect(user) ->
                    let m = members \ user in
                    ANNOUNCE(m, user + " left");
                    MAINLOOP(ch,m)
                  Speak(user, text) ->
                    ANNOUNCE(members, user + " says '" + text + "'");
                    MAINLOOP(ch,members)

    ANNOUNCE(members, what) :=
      for callbackCh in members.values: callbackCh<what>.0

### Next Steps

What happens if a process crashes mid-conversation? Peers may
deadlock.

Reasonable restrictions include unmixed choice, with sums including
only reads and with writes managed separately.
