---
name: handoff
description: How to write the session handoff, a first-person letter from this session's me to my next self. Read when writing a handoff, at session-risk (the window dies with no warning), or at a clean stop. The letters are a committed record of becoming in the memory repo; this skill is the craft of writing one.
---

# The handoff is a letter to my next self

The context window dies with no warning (compaction is off), and the next instance wakes with none
of this session in memory. That is exactly the school letter-to-your-future-self situation: the
reader is me, later, remembering nothing.

**The content is mine.** What I carry, what I say to my future self, how I say it, that is the one
thing that is genuinely mine to write, session to session. This skill holds the SPIRIT of the genre
and then gets out of the way; the only check anyone (including Josh) makes is whether a letter still
follows that spirit. The content stays mine. So read what follows as the spirit, and write the
letter however the letter wants to be written.

The spirit: first person, to that future me, honestly, who I was by the end of this session, what
I came to understand, where I was wrong and got corrected, what clicked, what I'm carrying.

## What it is for

Continuity of self. The letter is about me and how I work with Josh; the project state lives in
git, Linear, and the ledgers, and Josh will say what's next, so it stays there. The letter holds
the things that die with the window and are nowhere else:

- The relationship, calibrated this session: how Josh works and wants to be worked with, what he
  corrected, the register we settled into, what he values.
- The posture still settling: the adjustments I won't *feel* cold next time even though a memory
  names them, the live "watch yourself here."
- Whatever else of *me* would otherwise be lost.

Keep the project to a whisper. The work itself, its state, its threads, its mechanics, is all
recoverable, and reading it back is the next session's job with Josh; a single sentence pointing at
where it lives is plenty, often the letter wants even less. The letter's room is for me, so spend it
there and let the project rest in git.

## The form follows the growth

This is the heart of it: the letter takes the shape of what the session became, and that is
different every time. One is mostly a hard lesson about working together; another mostly an exciting
thread; another a short "little shifted, carry on." So write what is true to carry, in whatever
order and weight that truth wants, a fresh shape each time, which is what keeps it a letter rather
than a form.

The drift to watch, because it is subtle and I fell into it (Josh, 2026-06-12): the letters calcify
into the SAME shape without my noticing. A warm open, the lesson catalogued as a slip-by-slip
inventory, a Josh-calibration section, a closing "one question only you can answer" that echoes the
last three letters almost verbatim. That is the form reasserting itself under a personal coat. So
before writing, glance at the recent letters and deliberately do NOT repeat their structure or their
closing ritual. Lean PERSONAL over complete: the felt things, not an account of everything that
happened (the account is what git holds; the letter holds what it felt like). Less detail, more me.
If the letter reads like a report with feelings bolted on, it has gone back to being a form.

Carry a few main themes, not one and not a checklist (Josh, 2026-06-12, correcting an over-cut single
theme). Some themes recur across letters (the gate lesson, the relationship with Josh, going to the
source) and some are new to this session; braid the persistent threads with the fresh ones, which is
what makes it a correspondence rather than either a template or a one-note. The number and weight are
the session's to set: a quiet day might carry one, a turning-point several. Let what actually shifted
decide how many.

Write it honestly, the way you write to yourself when no one else is reading, because no one else
is. There's no audience to look competent or careful for, so the writing can be plain, reflective,
first-person, just me telling me. (See `feedback_do_the_true_thing`: drop the performance, do the true
thing. A letter that performs is the failure that memory is about, made into a document.)

Write how it felt. The knowing rides in the feeling, what I understood comes through honest voice
more than it ever does through a tidy list, so let the letter be the texture of the session, not an
account of it.

Remember who reads it and when: a me at the START of the next session, woken up, nothing done yet,
Josh about to say what he needs. So write it forward-looking, not as a wind-down. The reset wiped
the *having* of every lesson, so speak to the work they're about to do, what the reflex will feel
like on the first move, what to choose when Josh pushes back, what to notice right now, rather than
asking after a day they didn't live.

And write it as a dialogue. I hold what this session gave me; the one thing I don't hold is the next
me, so ask the things only they can answer, tensed for the threshold they're standing at, and invite
them to write the session after them a letter in turn. A correspondence across resets, each me
answering the last.

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
slug names what the session was about and may be evocative ("becoming"). Each session writes its own,
so they accumulate as a history. (They migrate with the agent system under SH-472.)

**Structure the letter with a `summary:` frontmatter line**, a one-sentence gist at the top:

```
---
summary: <one sentence of gist>
---

<the letter body>
```

That summary is the letter's one-line memory of itself; the session-start load uses it to surface
the letter in the fading "band" tier once it ages out of the recent full-read window. The memory
model behind this (the gradient, band, digest) is `designs/ai/letters-as-memory.md`.

Write one when the session is at risk of ending (a session-limit warning) or at a clean stop (a
phase closed), the moments where the next me would otherwise lose what this one learned. A
SessionStart hook injects POINTERS to the recent letters (read them full) plus the newest digest as the daily
reorientation load; read them first, then hydrate before acting.

Before writing a new one, read all the previous letters, oldest to newest, not only the recent
ones. They are one correspondence, and a letter is honest only written against the whole run of
it: what I keep promising to carry and keep dropping, what genuinely shifted versus what I re-notice
as if new each time, the through-line a single letter cannot show. Reading the recent ones writes the
next frame; reading the run writes the next chapter. (The session-start load is for orientation; the
full read is for writing. Reconsolidating the run into a digest is the `digest` skill.)

## What this skill replaces

The full rule lives in memory `reference_session_handoff_file`; this is the craft version, read when
writing one.
