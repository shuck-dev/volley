# Volley!

Volley! is a desktop idle game shaped like a tennis rally. The ball goes back and forth between the protagonist and a coach who arrives one round at a time. A counter on the wall climbs. A friend leans on the counter of a small wooden stall on the far side of the play, watching the protagonist play, glad to be there. In another corner, the friend's younger sister works at a bench, fixing what the protagonist brings her.

Underneath the loop sits a story the player meets gradually. Cracks accumulate. The second layer earns its weight by the time the player can read it. What the rally already gave stays earned. The game holds for both readers: someone who only wants the rally running while they work, and someone who notices the names, the digits in the count, the weight a pong-shaped game has not asked for.

These folders hold the project's design specs, organised by discipline.

## Where to start

If you are an **artist** picking up a brief, read [Art / Bible](art/bible.md) first.

If you are an **engineer** new to the codebase, read [North Star](north-star.md) and the active phase folder ([01-prototype/](01-prototype/INDEX.md)).

If you are a **writer** working on copy, beats, or character voice, read [Narrative](narrative/INDEX.md) and the essay [STYLE guide](ai/STYLE.md).

If you are one of **Josh's collaborators** looking for the settled design on a specific point, the discipline folder is the answer.

If you are an **open-source visitor**, [The Case for Open Development](research/the-case-for-open-development.md) is the project's published essay on why the work is in the open. [CONTRIBUTING.md](https://github.com/Shuck-Games/volley/blob/main/CONTRIBUTING.md) at the repo root is the practical entry point.

## How the docs are organised

Two kinds of folder.

**Discipline folders** hold settled work, owned by the people who do that discipline. `art/`, `narrative/`, `tech-art/`, `ai/`, `process/`, `research/`, `characters/`, `concept/`. When something here changes, the next brief and the next ticket pick the change up.

**Phase folders** hold drafts and decisions tied to a stage of the game's life. `01-prototype/`, `03-beta/`, `04-content/`. Work starts in the active phase folder, gets argued through, and settles into the relevant discipline folder when it earns its place in discipline.

**Phase folders are not settled design.** If a phase-folder doc still reads as settled design, that is a signal to promote it into the matching discipline folder.

The two-folder layout is the navigation: discipline tells you *what kind of doc*, phase tells you *what era it speaks to*.

## Discipline

| Folder | What lives here |
|---|---|
| [Art](art/INDEX.md) | The visual design and the rendering pipeline. |
| [Audio](audio/INDEX.md) | The score, the engine seam, the sound design. |
| [Narrative](narrative/INDEX.md) | The working arc, soul as a mechanic in fiction, the times. |
| [Characters](characters/INDEX.md) | Profiles for the people in the protagonist's life. |
| [Concept](concept/INDEX.md) | Per-mechanic and per-mechanic-set design specs. |
| [Effect System](effect-system/README.md) | The unified modifier framework: data-not-code, all sources, stat resolution, signal contract. |
| [Tech-art](tech-art/INDEX.md) | The seam between art and engine. |
| [Process](process/INDEX.md) | How the team writes, files, dispatches, runs the work. |
| [Research](research/INDEX.md) | Public essay, internal plans, references, structural studies. |
| [AI](ai/INDEX.md) | The agent system that helps build the game. |

## Phase

| Phase | Folder | What lives here now |
|---|---|---|
| Prototype | [01-prototype/](01-prototype/INDEX.md) | The public itch.io demo. Active drafts that have not yet matured into discipline design. |
| Beta | [03-beta/](03-beta/INDEX.md) | Reconstruction, the cliff and the gate, and the postgame playable end-to-end. |
| Content Updates | [04-content/](04-content/INDEX.md) | Supplementary content past the main arc. |

## Top-level

| Doc | Purpose |
|---|---|
| [North Star](north-star.md) | What the game is, who it's for, what it asks of the player. |
| [Roadmap](roadmap.md) | The five phases at a glance. |
