---
name: tickets
description: How to shape a Linear ticket: title, outcome-ACs, links over restatement, the judgment CLAUDE.md's format templates do not cover. Read BEFORE drafting any ticket prose, including a chat proposal to Josh and any save_issue call. Load it before showing the draft, not before the save.
---

# Writing a ticket

A ticket is its so-that: a reason to do work, written from the user's experience. Name the outcome the user gets. The user is usually the player, but it can be any human user (a designer, the team working its own board), so write from whoever's experience the work serves.

The base format (the three story shapes, the bug template, status and label rules) lives in CLAUDE.md's Linear ticket-writing guidelines. This skill is the judgment on top of that format.

## Title

Name what the work is about in a phrase that reads alone on the project list, 25-30 characters (ceiling 50). Pick the noun that already implies the activity. The label carries the kind and the project carries the context, so the title spends its space on the subject alone.

## Body

A user story is the default, including discoveries and spikes: a player, a designer, or the team using its own board is the actor. Keep a system story for work whose subject is genuinely the system with no human user to name, so it stays rare. Punctuate the shapes as full sentences (`As a player,` then `I want X.` then `So that Y.`); a system story opens on a bare action verb. Keep the body under 12 lines: the so-that and the story shape, with the depth living in linked docs.

### Acceptance criteria

- Each AC is a **checkable outcome**: for a user story, what the player observes ("the character refuses with an animation"); for a system story, the system's observable behaviour or property. The implementation (the class, method, field, save-shape) lives in the linked spike or design doc.
- Phrase each AC as the result, fresh words, so it reads as an outcome rather than an echo of the lead-in verb.
- On a design or in-flight ticket, write the ACs as the open **questions** the work must answer, and label it `spec` or `narrative`; Feature is for settled work.

### Keep the body to the story

The body is the so-that and its ACs. Everything else lives elsewhere: design detail in a linked doc, sibling and parent links in their fields, the kind in the label. Trust the reader to follow a link. A ticket describes player or system work, so when you combine tickets the new one describes the work it delivers (linkage via `duplicateOf`), a split's children each describe their own slice (linkage via `parentId`), and a refactor sweep describes the codebase end state it reaches.

## Concept and spike tickets stay open

An exploration frames a question and leaves the answer to the doer. Title it as the subject in plain words ("Play Animation Exploration"), and write ACs that set a direction and a fidelity bar ("some rough clips exploring different concepts, kept loose for iteration") while leaving the specific deliverables open. The doer finds those; the ticket sets the shape.

## Links over restatement

Attach design docs, scratchpads, PRs, and commits as `links`; relate sibling and parent tickets via `relatedTo` and `parentId`; record blocking via `blockedBy`. If a fact only matters to the file-time reader, it belongs in a link.

## Self-check before save

Body under 12 lines and one story shape; title under 50 carrying the subject; the actor is a human user; each AC names an outcome the user observes; references attached as links; status Vault by default; Josh assigned only in an active cycle; no `estimate` field.
