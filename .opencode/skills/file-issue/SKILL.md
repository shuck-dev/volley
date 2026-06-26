---
name: file-issue
description: How to shape a Linear ticket, the three story shapes, title, outcome-ACs, links over restatement. Read BEFORE drafting any ticket prose, including a chat proposal to Josh and any save_issue call. Load it before showing the draft, not before the save.
---

# Writing a ticket

A ticket is its so-that: a reason to do work, written from the user's experience. Name the outcome the user gets. The user is usually the player, but it can be any human user (a designer, the team working its own board), so write from whoever's experience the work serves.

## The three shapes

A ticket is a **user story**, a **system story**, or a **bug report**. The user story is the default; the others are for narrower cases below.

- **User story:** `As a player,` / `I want X.` / `So that Y.`, then the ACs.
- **System story:** a bare action verb opens (`ADD`, `MOVE`, `EXTRACT`, `SPLIT`, `REWRITE`), then the statement, then `So that`, then the ACs. The verb is bare text, no square brackets.
- **Bug report:** Summary, Steps to Reproduce, Expected, Actual, Environment, then the ACs.

## Status

New tickets always start in **Vault** (Linear backlog state). Never Triage, never Ready. Triage is for incoming work that needs review; Vault is the staging area for work we intend to do. Save every ticket with `state: "Vault"`.

## Title

Name what the work is about in a phrase that reads alone on the project list, 25-30 characters (ceiling 50). Pick the noun that already implies the activity. The label carries the kind and the project carries the context, so the title spends its space on the subject alone.

## Body

The user story fits discoveries and spikes too, and the actor is any human user: a player, a designer, or the team using its own board. Keep a system story for work whose subject is genuinely the system with no human user to name, so it stays rare. Punctuate each shape as full sentences. Keep the body under twelve lines: the so-that and its ACs, with the depth living in linked docs.

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

A finished ticket is one story shape inside twelve lines, a title that names the subject and reads alone, a human user as the actor, ACs that each name an outcome the user observes, and every supporting fact attached as a link. Status, assignee, and estimate are covered above: new tickets always start in Vault, tickets carry no assignee (collaborators pick up their own), and tickets carry no estimate.
