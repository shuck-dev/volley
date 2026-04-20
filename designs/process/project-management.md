# Project management

How Shuck shapes, sizes, splits, names, and orders Linear projects. Ticket-level guidance lives in [`ticket-writing.md`](ticket-writing.md); this doc is about the layer above.

## What a project holds

A project holds every ticket about one thing. Court covers the equip loop, the court visuals, and the court sfx. Cast covers concept art, animation, and character audio. Workshop covers the tinkerer's corner end to end: the space, the character, the mechanics, the sound.

Projects are thing-based and span disciplines. They are not discipline buckets. Art and tech and audio for the same thing live in the same project so the work around that thing stays coherent.

## How to size

A project should fit inside one milestone's worth of work. If the scope can't ship together, it's probably two things, not one.

Foundations (Art Foundation, Music Direction) and ops projects (Demo Release, Security Hygiene) are exceptions. They exist to enable other projects or to carry cross-cutting work and are sized by the window they own, not by a single shipping milestone.

## When to split, when not to

Split when the project has grown past one milestone, when two scopes inside it now have different target dates, or when the work has diverged into two things that happen to share a name.

Do not split by discipline inside a project. A separate "Court Art" project alongside "Court Tech" breaks the principle above; use priority and `blocks` across tickets within one Court project instead.

## Naming

Project names are Title Case, two words max. "Art Foundation", "Game Feel", "Partner Unlock". If the concept needs more words, pick a tighter noun or split it into sibling projects. If splitting, each sibling follows the same rule.

## Ordering work across projects

Three levers, in order of preference:

1. **`blocks` between tickets.** Use this when a specific deliverable in one project gates a specific deliverable in another. The dependency is explicit and survives re-planning.
2. **Cycles.** Josh places a project's tickets into the active cycle when they're ready to ship. Unstarted projects stay in Backlog.
3. **Priority.** Use within a project to order tickets that share a cycle. Avoid using priority across projects as a substitute for `blocks`.

## Project dates

`startDate` and `targetDate` on a Linear project express the initiative's timeline: when that project needs to land for the initiative to hit its own deadline. Josh owns those dates. Agents do not set or change them, on any project, including new ones.

Move a date only when a project is done (it goes to Completed, `completedAt` carries the real closure date, the original `targetDate` stays as a historical marker) or when a project is confirmed behind and Josh directs the reschedule. A stale-looking date on an open project is a live signal, not noise.

Warn when a project has no dates. A missing `startDate` or `targetDate` is a gap to surface in cycle prep or health reads, so Josh can set it against the initiative timeline.

## Cycle management

Cycles are the scheduling layer below projects. Shuck's cycles are two weeks long, run Tuesday through Monday, and use the Monday before the next cycle as a buffer day for closeout and planning.

**Only the current cycle is planned.** The next cycle exists with a name for continuity but its contents are not chosen ahead of time. Plan a cycle when it becomes current; treat "prep the next cycle" as naming it, not populating it.

**Cycles are named alphabetically after famous puppets.** One letter per cycle, marching A → Z. Check the most recent cycle's letter before proposing the next one (for example, if the last named cycle was Bobo, the next is a C puppet).

**Cycle descriptions are flat short sentences.** Linear's compact cycle preview collapses markdown lists and renders bullet characters as literal text, so no "Goals:" header, no bullet list — one flat line of full-stop-separated sentences.

**Any project with a target date inside a cycle must be either scoped into that cycle or have its dates moved.** Don't let a project silently miss its `targetDate`: either promote its remaining tickets to Ready and pull them into the cycle, or Josh moves the dates. This applies to parallel and foundation projects too.

**Promote to Ready before entering the cycle.** Backlog is unscoped; tickets move to Ready once they have everything a human or the headless bot needs to pick them up (spec, AC, design links via Linear's native attachment fields, any `blocks` or `relatedTo` wired). Only then do they enter the cycle.
