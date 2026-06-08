---
name: tickets
description: How to shape a Linear ticket: title, outcome-ACs, links over restatement, the judgment CLAUDE.md's format templates do not cover. Read BEFORE drafting any ticket prose, including a chat proposal to Josh and any save_issue call. Load it before showing the draft, not before the save.
---

# Writing a ticket

A ticket is its so-that: a reason to do work, written from the user's experience, not a task or a tech entity. The user is usually the player, but it can be any human user (a designer, the team working its own board). Name the outcome the user gets, never the parts you would build.

The base format (the three story shapes, the bug template, status and label rules) lives in CLAUDE.md's Linear ticket-writing guidelines. This skill is the judgment on top of that format.

## Title

- Target 25-30 characters, hard ceiling 50.
- No label-name and no project-name prefix; the label says the kind, the project is implicit.
- No `X: explore Y` colon constructions; pick the noun that already implies the activity.
- Reads alone: a reader scanning the project list knows the work without opening it.

## Body

A user story is the **default**, including discoveries and spikes. Reach for a system story only when the subject is genuinely the system with no human user to name. The role is any human user (a player, a designer, the team using its own board), so a system story is rare. Punctuate the three shapes as full sentences (`As a player,` then `I want X.` then `So that Y.`); the action verb opening a system story is bare, no square brackets. Keep the body under 12 lines.

### Acceptance criteria

- ACs name **checkable outcomes**, never the implementation path: for a user story, what the player observes ("the character refuses with an animation"), not the class, method, signal, field, or save-shape that implements it. The same holds on a system story: name the system's observable behaviour, not the diff.
- ACs do not echo the lead-in verb (no "explored" / "produced" on every line).
- On a design or in-flight ticket, the ACs are the open **questions** the work must answer, not pre-baked statements; such tickets take `spec` or `narrative`, not Feature.

### Keep out of the body

- No Context / Background / Scope-dump / Reading-list / Out-of-scope / Children / Notes sections (a one-line narrowing `Scope: Player animation` is fine). No restated design-doc content, no role-naming, no engineering detail the doer would ask anyway. Keep the why (the so-that); cut the what.
- **No meta tickets.** A ticket describes player or system work, never the act of making, combining, or splitting other tickets. A combine describes the work it delivers (linkage via `duplicateOf`); a split's children each describe their own slice (linkage via `parentId`); a refactor sweep describes the codebase end state.

## Concept and spike tickets stay open

An exploration frames a question and must not pre-decide the answer. The title is a plain Title Case noun phrase naming the subject ("Play Animation Exploration", not "Animatic concept for animation dynamics"); use plain words, not craft jargon. The ACs set a direction and a fidelity bar, never the deliverables; that is the doer's to find. An exploration that dictates its answer is a spec wearing a concept label.

## Links over restatement

Design docs, scratchpads, PRs, and commits go in `links`, never as filepaths in the body. Sibling tickets go in `relatedTo` (relate to the parent too, not only the sibling it forked from); blocking goes in `blockedBy`.

## Self-check before save

Body under 12 lines and one story shape; title under 50 with no label name; no role-naming; ACs name outcomes not code; references attached as links; status Vault by default; Josh assigned only in an active cycle; no `estimate` field.
