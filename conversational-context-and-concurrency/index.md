# Conversational Context & Concurrency

**Tony Garnock-Jones <tonyg@ccs.neu.edu>**, 31 Jan 2017.

 - [Talk outline](index.md)
 - Computational models:
    - [Monitors](monitors.md)
    - [Actors](actors.md)
    - [Channels](channels.md)
    - [Tuplespaces](tuplespaces.md)

## Paper list

[1] P. Brinch Hansen, “Monitors and Concurrent Pascal: A Personal
History,” ACM SIGPLAN Not., vol. 28, no. 3, pp. 1--35, 1993.
([Copy 1](http://dl.acm.org/citation.cfm?id=155361); [Copy 2](http://thecorememory.com/MonConPas.pdf))

[2] C. Hewitt, P. Bishop, and R. Steiger, “A universal modular ACTOR
formalism for artificial intelligence,” in Proc. International Joint
Conference on Artificial Intelligence, 1973, pp. 235–245.
([Copy 1](https://eighty-twenty.org/files/Hewitt,%20Bishop,%20Steiger%20-%201973%20-%20A%20universal%20modular%20ACTOR%20formalism%20for%20artificial%20intelligence.pdf) is a scan I made from an original; [Copy 2](http://ijcai.org/Proceedings/73/Papers/027B.pdf) is the official online version, which unfortunately has bad OCR and is hard to read)

[3] G. A. Agha, “Actors: A Model of Concurrent Computation in
Distributed Systems,” Technical Report 844. MIT Artificial Intelligence
Laboratory, Jun-1985.
([Copy 1](https://dspace.mit.edu/bitstream/handle/1721.1/6952/AITR-844.pdf); [Copy 2](http://www.cypherpunks.to/erights/history/actors/AITR-844.pdf))

[4] C. Fournet and G. Gonthier, “The Join Calculus: a Language for
Distributed Mobile Programming,” Applied Semantics Summer School,
September 2000, Caminha, Portugal.
([Copy 1](http://research.microsoft.com/en-us/um/people/fournet/papers/join-tutorial.pdf))

[5] N. J. Carriero, D. Gelernter, T. G. Mattson, and A. H. Sherman, “The
Linda alternative to message-passing systems,” Parallel Comput., vol.
20, no 4, pp. 633--655, 1994.
(Very hard to find online. [This](Carriero et al. - 1994 - The Linda alternative to message-passing systems.pdf) is the copy that I scanned myself. Heather Miller has an annotated version [here](http://heather.miller.am/teaching/cs7680/pdfs/Linda-Alternative-to-Message-Passing.pdf))

## Introduction: Conversational Context

When programs are written with concurrency in mind, the programmer
reasons about the interactions between concurrent components or agents
in the program. This includes exchange of information, as well as
management of resources, handling of partial failure, collective
decision-making and so on.

These components might be objects, or threads, or processes, or
actors, or some more nebulous and loosely-defined concept; a group of
callbacks, perhaps. The programmer has the notion of an agent in their
mind, which translates into some representation of that agent in the
program.

We think about the contexts (because there can be more than one) in
which agents exist in two different ways.

From each agent's perspective, the important thing to think about is
the boundary between the agent and everything else in the system.

But from the system perspective, we often think about *conversations*
between agents, whether it's just two having an exchange, or a whole
group collaborating on some task. Agents in a conversation play
different roles, join and leave the group, and build shared
conversational state.

In this lecture I'm going to use the idea of these *conversational
contexts* as a lens through which to view the development of various
metaphors and mechanisms of communication and coordination.

Basically, I'm going to present four *computational models* for
concurrent interaction. These aren't full programming languages, but
there are many *programming models* that build upon them. In some
cases, development of these ideas has progressed all the way up to
*system models* including user interaction and so forth.

((Four whiteboards: (left) 1 2 3 4 (right).))

((WB4: Historical timeline))

The computational models I'm going to examine are

 - monitors, and shared memory concurrency generally
    - Brinch Hansen's HOPL II retrospective, 1993
       - Dijkstra 1965 - critical regions, semaphores ('62-'63?)
       - Hoare 1971 - conditional critical regions
       - Brinch Hansen 1971 - important refinements, genesis of the idea
       - Discussions D/H/BH 1971
       - BH and H publish independent notation designs 1973
       - widely influential, e.g. Java 1994ish (**)
 - the actor model
    - Hewitt, Bishop, Steiger 1973
    - many, many more 70s-80s
    - Agha 1985
    - De Koster, Van Cutsem, De Meuter 2016 - taxonomy of actors (**)
 - channel-based communication
    - Hoare 1978 - CSP, communicating sequential processes
    - Milner 1980 - CCS, calculus of communicating systems
    - Hoare 1985 - CSP book
    - Milner, Parrow, Walker 1992 - π calculus (**)
    - Fournet & Gonthier 2000 - join
 - tuplespaces
    - Gelernter 1985 - Linda
    - Gelernter, Carriero 1992 - Coordination languages
    - Carriero, Gelernter, Mattson, Sherman 1994 - contra message-passing (**)
    - 1990s and 2000s: many Linda variants and languages including
      tuplespaces: LIME, KLAIM, AmbientTalk
    - Murphy, Picco, Roman 2006 - LIME retrospective

((The (**)s mark the sources most similar to the little models I'll be
presenting.))

This area is absolutely huge. Another major strand I don't have time
for is transactions in all their various forms.

The ones I've chosen have an interesting relationship, though: in some
ways, actors and channels separately are reactions to shared-memory
with synchronization primitives; and tuplespaces are a reaction to
message-passing designs like actors and channels.

But let's come back to the idea of conversational context.

Let's look at an example program to gain an intuition for the kinds of
things we want to be thinking about as we look at these computational
models.

((WB2: Chatroom example to build intuition))

We'll think about a simplified chat service a bit like IRC.

Diagram:

 - chatroom blob
 - blobs surrounding it denoting user agents
 - all encircled, delimiting the server
 - wiggly lines going through a cloud to clients
 - each client blob is connected through the cloud, but also out to a tty

First of all, we can see some really interesting communication
patterns here.

 - user agents interact with each other through a shared multicast
   medium representing the chat room itself
 - they also interact with client programs through two-party
   point-to-point bidirectional conversations: TCP sockets
 - the client program interacts with the server via TCP, but also with
   the user via a GUI. This latter conversation is quite complex and
   can be nonlinear - "non-modal interface design"

How well do our computational models support these patterns?

Second, we see that agents frequently engage in multiple conversations
at once.

 - all of them. If the chat room is an agent, it is engaged in
   multiple two-party conversations with the user agents in the
   system.

How do our computational models allow us to compose multiple
conversations?

Third, we see that there are interesting pieces of conversational
state held in common among participants in each conversation.

 - the user list and set of callbacks(etc) in the chat room
 - each TCP socket
 - widgetry for displaying UI

As an example of conversational state, consider the idea of
*presence*, and how it is used.

In a multi-party conversation, such as this chat room, you get
information about other participants as a set of names, and are kept
informed as that set changes over time.

In a two-party conversation, such as a TCP connection, you get
information about whether the other participant is still there or not
based on whether the socket is still open or has closed.

In both cases, you use that knowledge to decide whether or not it's
worth saying any particular utterance. If I need to contact either
Alice or Bob but neither are in the chat room, I know I needn't bother
saying anything until they show up.

If what I have to communicate involves some actual work, I may be able
to get away with delaying doing the work until Alice or Bob appears.
In this way, I've used the conversational context to efficiently
allocate resources: both not wasting my words, and not wasting my
compute time.

So presence information is a piece of conversational state that's
shared among the group and kept up to date as things change.

How do our computational models support signalling of relevant changes
to common state?

Notice that the user list is managed primarily here, in the chat room,
but has to be replicated all the way out here, and kept in sync. On a
smaller scale, the view of the user list has to be kept in sync with
the model, within the client program.

How do our computational models support maintenance of consistency of
replicas of information?

How do our computational models support integration of newly-received
signals of changes in state with local *views* on common state?

How do our computational models handle maintaining the integrity of
both common state and any application-level invariants that might
exist in the face of partial failure?

Finally, there are aspects of partial failure to consider, since we
have concurrent activities that can fail independently. What are the
consequences if some agent fails?

((WB1: Build up list of aspects of conversational context))

 - Communication patterns
 - Correlation and demux
 - Change in state
    - Signalling
    - Consistency
    - Integration
    - Integrity
 - Partial failure

As I present examples, also ask yourself:

 - are they correct?
 - are they easy to understand?

## Foundation: ISWIM

((WB4: ISWIM. Core syntax, evaluation contexts, beta. Note re:
syntactic sugar, data types, PURITY.))

## Monitors

In the early 1960s, people had started to grapple with the
difficulties of multiprogramming. The main approach, being quite
machine-oriented, was to think about many processes sharing a mutable
memory.

Monitors, as described by Per Brinch Hansen's 1993 HOPL-II
retrospective,

> "evolved from the ideas of Ole-Johan Dahl, Edsger Dijkstra, Tony
> Hoare, and [himself]"

between 1971 and 1973.

Dijkstra came up with the concept of semaphores around 1963, and in
1965 published on the idea of a *critical region* -- a block of code
accessing shared variables within which no more than one process could
find itself at once -- and showed how to implement critical regions
using semaphores.

Hoare proposed notation for identifying some variable as a shared
resource in 1971. The idea was to have a mutable variable that, in
some portions of code, was treated as guarded by critical regions, but
in other portions, was left alone. At the same time, he came up with
the idea of a *conditional critical region*, where entry to the region
is delayed until some predicate holds.

    data T = ...
    var X: T = ...
    with X when P(X) do { ... }

Monitors were developed to fix weaknesses of this idea:

 - it's unreliable: you can access the mutable state outside a critical region.
 - there's no way to prefer some waiters over others (priority scheduling)
 - it's inefficient: you just repeatedly evaluate all active `P`s until one is satisfied
 - it's messy: code relating to the structure and its operations isn't gathered into one spot

Monitors "enable concurrent processes to share data and resources in
an orderly manner" (Brinch Hansen 1993, p3).

The idea is that

 - the resource and its operations are syntactically colocated
 - no access to the resource without acquiring the lock
 - some operations may block: the operation's own code manages the
   suspension and resumption of clients as necessary.

There are a number of roughly-equivalent (according to Brinch Hansen)
formulations of the idea, all involving different ways of managing the
conditional suspension and resumption of processes accessing the
monitor in various ways.

Brinch Hansen works through lots of formulations, but I'm going to cut
to the chase and show something that's a bit like the monitorish
primitives that Java provides, although Java allows access to
resources outside of synchronized blocks, and allows access to the
lock external to the object itself. It's interesting that in Java's
use of monitor-like constructs, we see Hoare's original idea: it's
possible to write code that accesses a monitored bundle of state
outside the monitor!

[Simple model of Monitors](monitors.md).

Evaluation in terms of conversational context:

 - Communication patterns: On the one hand, you have to encode
   messaging, no matter the kind, and you have to very carefully think
   through the synchronization between senders and receivers. On the
   other hand, shared memory lends itself to multiway messaging just
   as easily as point-to-point messaging: you're free to encode any
   pattern you like directly in terms of shared memory.

 - Correlation and demux: Monitors, mutexes, semaphores etc *don't
   compose well*. If you need to wait for the first arriving event
   among two monitors implementing, say, channels - you're stuck. You
   might spin up a thread for each of the two reads that then delivers
   messages to a third channel after marking them with their source.

 - Change in state: signalling of state change has to be shoehorned
   into use of await and signal. There's no real problem with
   consistency of state, since there's generally only one replica of
   each piece of state. This makes integration of state changes also
   really easy: you just make the update to shared memory, and it's
   directly visible to your peers. However, maintaining integrity,
   either of the medium of communication (the resources owned by a
   monitor) or higher-level application invariants, is completely up
   to the programmer; you hope that they've implemented each monitor
   correctly and that that's a sufficient foundation for achieving the
   wider goal.

 - Partial failure: the construct of monitors is too weak to give any
   nice way of declaring what should happen in case of a crash. It's
   unclear who to blame for any given exception, since there are
   multiple processes involved and any one of them could have
   performed the action that led to the exception. You might even have
   many *logical* processes on the stack at once, even though you're
   executing only one *physical* process.

## Actors

The original 1973 actor paper by Hewitt, Bishop and Steiger in the
International Joint Conference on Artificial Intelligence, is
incredibly far out! It's a position paper that lays out a broad and
colourful research vision. It's packed with amazing ideas.

The heart of it is that Actors are proposed as a universal programming
language formalism ideally suited to building artificial intelligence.

The goal really was A.I., and actors and programming languages were a
means to that end. Later researchers developed the model into a
programming model in its own right, separating it from its A.I. roots.

In the mid-to-late 70s, Hewitt and his students Irene Greif, Henry
Baker, and Will Clinger developed a lot of the basic theory of the
actor model, inspired originally by SIMULA and Smalltalk-71. Irene
Greif developed the first operational semantics for it as her
dissertation work and Will Clinger developed a denotational semantics
for actors.

In the late 70s through the 80s and beyond, Gul Agha made huge
contributions to actor theory. His dissertation was published as a
book on actors in 1986 and has been very influential.

Actor-based languages come in wide variety; De Koster et al.'s 2016
taxonomy classifies actor languages into four groups. I won't go into
detail, but this model is a process-style variation, more like Erlang
than the more classic Actor languages. So if you go look at Agha's
work, it'll look quite different. There was a HOPL-III paper from Joe
Armstrong on Erlang.

[Simple model of Actors](actors.md).

 - Communication patterns: You get point-to-point, multiple-sender
   single-receiver messaging. That's it. If you need anything else,
   you have to encode it. A really common pattern is to implement the
   *OBSERVER PATTERN* with an actor which broadcasts messages to a
   list of subscribers. If you need shared memory, you have to encode
   that as an actor, too. In each of these cases, you've effectively
   *reified the medium of communication*.

 - Correlation and demux: Actors can wait for multiple events at once,
   though in order for them to tell which is which, the messages
   themselves have to carry the correlation identifiers. This seeming
   weakness can also be viewed as an advantage: instead of having to
   use some implementation construct to determine context, you get to
   use domain-relevant aspects of received messages.

 - Change in state: signalling of state change is easy - send a
   message! - but maintaining consistency is now an interesting
   challenge because multiple replicas exist. Even in cases where
   there's some authoritative record of a piece of mutable state,
   recipients of notifications of change to that record must manually
   integrate the change with their own local state, which might be a
   simple replica of the remote state, or might be some function of it
   computable in terms of a sequence of change notifications.
   Maintaining integrity of the medium is easy, because when an actor
   crashes, the only recovery to shared state has to be to clean up
   that actor's routing table entry. Maintaining integrity of
   application invariants isn't directly helped by the model, although
   as we'll see, Erlang's "link" extension to the model does help.

 - Partial failure: A crashing actor can leave peers hanging waiting
   for a reply. To address this, Erlang introduced the idea of a link,
   which lets an actor declare a kind of conversational dependency on
   another actor. If a linked actor fails, the linking actor can
   receive an *exit signal* describing the failure. Erlang programs
   can use this to great effect to clean up state after a crash:
   recipients of an exit signal can clean up local context and
   reestablish application invariants. Exit signals are the foundation
   of a famous aspect of Erlang programming, *supervisors*.

## Channels

Channels are conduits through which messages travel between processes.

They have a buffer associated with them: if the buffer has zero
places, then the channel is *synchronous*; if it has an unbounded
number of places, it is *asynchronous*; otherwise, it's somewhere in
between.

As part of the road to monitors, in 1971 Hoare proposed an attempt at
a monitor-like idea that involved a "description of parameter
transfers as unbuffered input/output", which "later became the basis
for the concept of *communicating sequential processes*". CSP involves
a construct very similar to channels, alongside many other features
and mechanisms. The first publication on CSP is from 1978, but the
best introduction to CSP is Hoare's book, first published in 1985 and
frequently updated since.

Separately, Milner developed the *calculus of communicating systems*,
first published in 1980. I don't know how much influence from CSP
there was on his thinking. The two are clearly comparable.

CCS led subsequently to the π calculus, which has been hugely
influential. The π calculus is a very minimal computational model
based entirely around channels and processes, with very little else
involved. Milner, Parrow and Walker first published on π calculus in
1992.

Lots and lots of π-like derivatives sprung up during the '90s and
subsequently, including the paper on the Join calculus that I chose
for this talk. It's a lovely model and a really good paper, but the
model I'll present here is simpler than Join. It's roughly equivalent
to a simple synchronous-π-calculus extension of ISWIM.

[Simple model of Channels](channels.md).

 - Communication patterns: You get point-to-point, multiple-sender,
   multiple-receiver messaging. Anything else, you have to encode,
   just like with actors. However, languages based around channels
   *sometimes* have shared memory, and *sometimes* have isolated
   processes. Where shared memory exists, it can be judiciously used
   to work around channel restrictions, but suffers then from many of
   the problems we saw with monitors.

 - Correlation and demux: Most channel languages offer a kind of
   "select" or "choice" construct for waiting for many events at once.
   This is really powerful: a non-selected event *cannot happen*, so
   there's no cleanup to be done. Channels can be used as a kind of
   *placeholder* representation for conversational context: if each
   conversation a process is having takes place on a separate channel,
   a "select" statement can be used to distinguish between them. On
   the other hand, they're implementation rather than domain
   constructs. If there's no clean mapping onto channels, you again
   have to encode your conversational contexts some other way.

 - Change in state: As for actors, except that shared state may or may
   not exist depending on the language, and because channels aren't
   *owned* by any given process, there's little to be done to recover
   in case of a crash.

 - Partial failure: a crashing process might leave peers hanging, and
   there's no obvious means of adding an exit-signal-like feature to a
   channel-based model to propagate failures along relevant
   conversational links.

## Tuplespaces

In 1985, David Gelernter published his first paper on Linda, a
programming language based around a new idea, *tuplespaces*.

A tuple space is a data store shared by a group of processes that
interact with it by placing data items called *tuples* into it, and
retrieving them by *pattern matching*. Once a tuple is placed into the
store, it takes on independent existence. Tuplespaces are a little
like relational databases in this way: an inserted row doesn't just
vanish by itself.

Gelernter and his colleagues continued to work on this throughout the
80s and 90s, and lots and lots of Linda-inspired systems have appeared
over the years. In 1994, Carriero, Gelernter, Mattson and Sherman
published the paper I listed, where Linda is explicitly positioned
against message-passing systems. I think they're aiming for a contrast
between message-passing approaches to parallelism, for scientific
computing, rather than for general concurrency.

The basic Linda model has a couple of severe shortcomings that I'll
talk about in a moment, and lots of the variations over the years have
been attempts to fix the model. Here, I'll be presenting the original
basic Linda tuplespace model.

[Simple model of Tuplespaces](tuplespaces.md).

 - Communication patterns: Tuplespaces are really weird and
   interesting! They're intrinsically multicast, and reminiscent of
   publish/subscribe communication, but the basic Linda primitives are
   too weak to express pub/sub! An extension called `copy-collect`
   (a.k.a `ing`, `rdg`) is one option for adding to the power of the
   system, allowing *all* matching tuples to be retrieved or copied,
   rather than just a single tuple.

 - Correlation and demux: `in` and `rd` both block. There's no way to
   wait for the first of a number of possible interactions to occur.
   However, tuples are retrieved by pattern match, so you can use
   domain-relevant ways of distinguishing incoming tuples in some
   cases; you could take the approach of having relay processes to
   multiplex two distinct inputs, as for monitors. For this reason,
   some extensions include `inp` and `rdp` which *poll*, and others,
   like LIME, include *reactions*, which are effectively
   *subscriptions* to the appearance of tuples matching a pattern.
   When a matching tuple is `out`ed, installed reactions all fire and
   their callbacks run.

 - Change in state: Signalling of change happens automatically with
   publishing of a tuple; any waiting `in`s, `rd`s or reactions get
   the new tuple. There's no particular support for maintaining
   consistency among various replicas of the state in the tuplespace,
   but these languages largely emphasise the tuplespace itself as the
   authoritative repository for state, and discourage building
   replicas of it per-process. Integration of knowledge learned from
   the tuplespace is likewise a bit of a manual process. The integrity
   of the tuplespace itself can be automatically maintained by the
   system, but as we've seen, it's easy to mess up application-level
   invariants.

 - Partial failure: There's no representation of a process within a
   tuplespace, so there's no real way to add Erlang-style links.
   Instead, research has focussed on approaches like wrapping
   transactions around `in`/`out` primitives, and adding
   *compensating* transactions to run in case of unexpected agent
   crashes.
