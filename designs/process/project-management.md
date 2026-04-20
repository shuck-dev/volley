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
