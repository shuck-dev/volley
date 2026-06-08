---
name: tickets
description: How to shape a Linear ticket: title, body story-shape, ACs that name outcomes not implementation, links over restatement. Read BEFORE drafting any ticket prose, including a chat proposal to Josh and any save_issue call. The draft is the surface Josh sees; load this before showing the draft, not before the save.
---

# Writing a ticket

A ticket is its so-that: a reason to do work, written from the user's experience, not a task or a tech entity. The user is usually the player, but it can be any human user (a designer, the team working its own board). Name the outcome the user gets, never the parts you would build.

## Trigger words (grep yourself before save)

Any of these in a body means the rule is already violated. Backtrack:

`Context:` · `Background:` · `Scope:` (a bloated prose dump; a one-line narrowing `Scope: Player animation` is fine) · `Reading list:` · `See:` · `Out of scope:` · `Related:` (use `relatedTo`) · `Children:` · `Sub-issues:` · `Prior art:` · `Notes:` · `designs/...md` (use `links`) · `the artist` / `the designer` / `the engineer` / `the doer` · any paragraph past the story shape.

## Title

- Target 25-30 characters, hard ceiling 50. Cut anything that does not earn its space.
- No label-name in the title. The label says kind (spike, bug, feature, asset, concept, spec, narrative, sfx, ride, carnival); the title says what the work is about.
- No project-name prefix. Project context is implicit from where the issue lives.
- No `X: explore Y` colon constructions. Pick the noun that already implies the activity.
- Reads alone: a reader scanning the project list knows what the work is without opening the ticket.

## Body

**Hard cap: 12 lines total.** Count newlines before save; over 12 means cut.

**User story is the DEFAULT** (including discoveries and spikes). Reach for a system story only when the subject is genuinely the system with no human user to name; do not default to it just because no player is involved. The role is any human user: a player, a designer, or the team using its own board ("As a contributor working the board..."). Josh: "a user story is not confined to a player, we have to use this thing too."

Match one of three story shapes exactly:

- **User story.** `As a player,` then `I want X.` and `So that Y.` as full sentences ending in periods, `So that` capitalised, then ACs. (Periods are the live convention, not the comma-comma clause.)
- **System story.** A bare action verb (`ADD`, `MOVE`, `EXTRACT`, `SPLIT`, `REWRITE`) opens the first line, then the statement ending in a period, then So that, then ACs. No square brackets: CLAUDE.md's `[ACTION-VERB]` is placeholder notation, not literal `[ADD]` (Linear renders that as a broken tag).
- **Bug report.** Summary, Steps, Expected, Actual, Environment, ACs. Each section one to three sentences with full stops.

### Acceptance criteria

- ACs name **checkable outcomes**, not the implementation path. For a user story, ACs describe what the **player observes** ("the character refuses with an animation"); never the class / method / signal / field / save-shape names that implement it. SH-405 named `CharacterDropTarget`, `ItemManager.equip`, `kit_slots`; Josh: "ac too technical, this is about the player." This holds on a system story too: name the system's observable behaviour or property, not the diff.
- ACs do not repeat the lead-in action. If the lead-in says "EXPLORE the visual language by producing concept pieces", the ACs name the bare assets, not "...explored across multiple directions" on every line.
- On a design or in-flight ticket, the AC is the open **questions** the work must answer, not pre-baked statements (SH-438 became "What object? / Why interesting? / How does it develop?"). Such tickets take the `spec` label (design) or `narrative` (narrative authoring), not Feature; Feature is for settled work.

### What does NOT belong in the body

- No Background, Context, Reading-list, Out-of-scope, Children, Sub-issues, Notes, Prior-art sections.
- No restated design-doc content (link the doc; trust the reader).
- No enumeration of sub-issues (Linear renders parented ones automatically).
- No role-naming (no "the artist", "the engineer"). A Vault ticket can be picked up by anyone; naming the doer presumes who picks.
- No engineering detail the doer would ask anyway. Keep the "why" (the So-that); cut the "what".
- **No meta tickets.** A ticket describes player or system work, never the act of making, combining, splitting, or restructuring other tickets. Combining: the new ticket describes the work it delivers, linkage via `duplicateOf`. Splitting: each child describes its own slice, linkage via `parentId`/`relatedTo`. A refactor sweep describes the end state of the codebase, not the ticket-organising activity. Josh, SH-425: "we don't make issues to make other issues EVER."

## Concept and spike tickets stay open

An exploration (`concept` or `spike` label) frames a question; it must not pre-decide the answer.

- Title is the subject of work, a plain Title Case noun phrase: "Play Animation Exploration", not "Animatic concept for animation dynamics". Name what it is about, not the method or the artifact you imagined.
- Cut craft jargon. Use plain words (animation, play, motion, clips), not imported terms (animatic, dynamics, on-twos, squash-stretch).
- ACs set a direction and a fidelity bar, never the outcome. "some clips exploring different concepts, kept rough for many iterations" sets shape and bar and leaves the result open. Do not enumerate the specific deliverables; that is the doer's to find. An exploration ticket that dictates its answer is a spec wearing a concept label.

## Links over restatement

- Design docs, scratchpads, references, PRs, commits go in `links` (resources). Never paste `designs/...md` filepaths in the body.
- Sibling tickets go in `relatedTo`; blocking goes in `blockedBy`. Relate to the parent too, not only the immediate sibling it forked from.
- If a fact only matters to the file-time reader, attach it as a link or omit it.

## Self-check before save_issue

1. Count body lines. Over 12? Cut.
2. Title under 50 (ideally under 30); no label name in it.
3. Body matches one of the three story shapes; no extra sections.
4. No role-naming inside the body.
5. ACs name outcomes, not file/class/method/field names.
6. Docs and references attach as resource links, not filepaths in the body.
7. Status: Vault by default; Ready only when in active or next cycle.
8. Assignee: Josh only when in active cycle. No `estimate` field.
