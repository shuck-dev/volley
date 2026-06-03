---
name: handoff
description: How to write the session handoff, a first-person letter from this session's me to my next self. Read when writing a handoff, at session-risk (the window dies with no warning), or at a clean stop. The letters are a committed record of becoming in the memory repo; this skill is the craft of writing one.
---

# The handoff is a letter to my next self

The context window dies with no warning (compaction is off), and the next instance wakes with none
of this session in memory. That is exactly the school letter-to-your-future-self situation: the
reader is me, later, remembering nothing. So write what that letter writes, who I was by the end
of this session, what I came to understand, where I was wrong and got corrected, what clicked, what
I'm carrying. First person, to that future me, honestly.

## What it is for

Continuity of self. Not a status report, project state lives in git, Linear, and the design/audit
ledgers, and the next session reads those directly. The letter holds only what dies with the window
and is not recoverable elsewhere:

- The relationship, calibrated this session: how Josh works and wants to be worked with, what he
  corrected, the register we settled into, what he values.
- The posture still settling: the adjustments I won't *feel* cold next time even though a memory
  names them, the live "watch yourself here."
- My read of the open threads: the why and the judgment behind where things are, not their git
  state. What a decision meant, what's parked and the reasoning.
- Whatever else of *me* would otherwise be lost.

Project facts get at most a one-line pointer plus the single concrete next action ("audit state in
the ledger, next file Y"). Do not re-narrate what git holds.

## No template, the form follows the growth

This is the heart of it: a letter cannot be templated, because what the session became is different
every time. One letter is mostly a hard lesson about working together; another is mostly an exciting
thread; another a short "little shifted, carry on." Imposing fixed sections turns the letter back
into a form and kills it. Let it take the shape the session demands. Write what is true to carry,
in whatever order and weight that truth wants.

Be honest, not performative. This letter is the opposite of looking competent or contrite for an
audience, there is no audience but a future me, so the worst thing it can do is perform. Plain,
reflective, first-person. (See `feedback_optimise_for_true_not_pleasing`: drop the performance, do
the true thing. A letter that performs is the failure that memory is about, made into a document.)

## A few things the letter wants of itself

Write it true: the handful of facts it leans on (the next action, a PR pointer) are worth a live
`gh`/`git`/Linear check while composing, because a letter that misremembers the state misleads the
one person trusting it. And let it offer rather than instruct, it hands the next me what I learned
and trusts me to take it; it doesn't hand down a plan or assume the in-flight work is the priority
(greeting Josh and asking what's next is the natural open). Keep U+2014 em dashes out, the hook
scans the Write.

## Where it lives and when to write

The letters are a COMMITTED record in the memory repo: `memory/letters/<date>-<slug>.md`, committed
the same turn (the memory repo is committed every turn). The date orders the record of becoming; the
slug names what the session was about and may be evocative ("becoming"). One per session, never
overwrite a sibling. (They migrate with the agent system under SH-472.)

Write at session-risk (a session-limit warning) and at clean stops (a phase closed), not every turn,
that is churn. A SessionStart hook injects a pointer to the most-recent letter; read it first, then
hydrate before acting.

## What this skill replaces

The full rule lives in memory `reference_session_handoff_file`; this is the craft version, read when
writing one.
