
 - [Talk outline](index.md)

## Simple model of Actors

Start from λ-ISWIM.

Key properties:

 - process-style actors
 - nondeterministic scheduling, because of the quotienting by `≡`

### Syntax

    Expressions e := ... | spawn e | self | receive | send e e | ℓ
    Values  u,v,w := ... | ℓ

    Proc. tab.  T := ℓ:(v̅, e) | T|T
    Queued msg  q := v⇒ℓ
    Machines    M := <q̅, T>

    Expr ctxt   E := ... | send E e | send ℓ E

Programs are those `e` that are closed and do not mention any `ℓ`.

The starting configuration for a program `e` is `<·, ℓ:(·,e)>`.

### Structural Equivalence

Structural equivalence `≡` over machines includes:

 - Par operator `|` associative, commutative.

### Reductions

Read the following reduction rules as quotiented by `≡`.

    base    e ↪ e'  ⇒ ...| ℓ:(v̅,E[e])  →  ...| ℓ:(v̅,E[e'])

    spawn   <q̅, T | ℓ:(v̅, E[spawn e])>  →  <q̅, T | ℓ:(v̅,E[ℓ']) | ℓ':(·,e)>
    self    <q̅, T | ℓ:(v̅, E[self])>     →  <q̅, T | ℓ:(v̅,E[ℓ])>
    recv    <q̅, T | ℓ:(uv̅,E[receive])   →  <q̅, T | ℓ:(v̅,E[u])>

    send    <q̅, T | ℓ:(v̅, E[send ℓ' u])>  →  <q̅ u⇒ℓ', T | ℓ:(v̅,E[ℓ'])>

    deliver <u⇒ℓ q̅, T | ℓ:(v̅,e)>  →  <q̅, T | ℓ:(v̅u,e)>

### Examples

Are these correct? Are they easy to understand?

One-place buffer:

    data Command = Get(pid)
                 | Put(value,pid)

    NEW() := spawn wait([], NONE, [])
               where wait(readers, buf, writers) =
                       match receive
                         Get(pid) -> work(readers ++ [pid], buf, writers)
                         Put(value,pid) -> work(readers, buf, writers ++ [(value,pid)])
                     work(readers, NONE, ((value,pid) : writers)) =
                       send pid (); work(readers, SOME value, writers)
                     work((r : readers), SOME value, writers) =
                       send r value; work(readers, NONE, writers)
                     work(readers, buf, writers) =
                       wait(readers, buf, writers)

    GET(b) := send b Get(self); receive

    PUT(b,v) := send b Put(v,self); receive

Zero-place buffer (synchronous channel):

    NEW() := spawn wait([], [])
               where wait(readers, writers) =
                       match receive
                         Get(pid) -> work(readers ++ [pid], writers)
                         Put(value,pid) -> work(readers, writers ++ [(value,pid)])
                     work((r : readers), ((v,w) : writers)) =
                       send r v; send w (); work(readers, writers)
                     work(readers, writers) =
                       wait(readers, writers)

Queue (asynchronous channel):

    NEW() := spawn wait([], [])
               where wait(messages, readers) =
                       match receive
                         Get(pid) -> work(messages, readers ++ [pid])
                         Put(value) -> work(messages ++ [value], readers)
                     work((m : messages), (r : readers)) =
                       send r m; work(messages, readers)
                     work(messages, readers) =
                       wait(messages, readers)

Chat room:

    data Command = Connect(user, callbackCh)
                 | Disconnect(user)
                 | Speak(user, text)

    CHATROOM() := spawn MAINLOOP({})

    MAINLOOP(members) :=
      match receive
        Connect(user, callbackPid) ->
          for peer in members.keys: send callbackPid (peer + " arrived")
          let m = members{user ⟼ callbackPid} in
          ANNOUNCE(m, user + " arrived");
          MAINLOOP(m)
        Disconnect(user) ->
          let m = members \ user in
          ANNOUNCE(m, user + " left");
          MAINLOOP(m)
        Speak(user, text) ->
          ANNOUNCE(members, user + " says '" + text + "'");
          MAINLOOP(members)

    ANNOUNCE(members, what) :=
      for callbackPid in members.values: send callbackPid what

### Next Steps

What happens if an actor crashes mid-conversation? Peers may
deadlock. One solution: Erlang-style monitors.

What happens if someone sends us a request while we're waiting for the
reply to a `GET` or `PUT`? Selective receive; or, actor-wide transform
to lift continuations to actor-wide continuation table. With selective
receive, one-place buffer becomes:

    NEW() := spawn (rec mainloop() .
                      receive
                        Put(value,wpid) ->
                          send wpid ();
                          receive
                            Get(rpid) ->
                              send rpid value;
                              mainloop())

and zero-place buffer becomes:

    NEW() := spawn (rec mainloop() .
                      receive
                        Put(value,wpid) ->
                          receive
                            Get(rpid) ->
                              send rpid value;
                              send wpid ();
                              mainloop())
