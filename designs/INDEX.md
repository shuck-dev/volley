# Volley!

Volley! is a desktop idle game shaped like a tennis rally. A small window sits on the player's desktop, the ball goes back and forth, and the player builds a paddle worth keeping. Underneath the loop is a story: a protagonist who built a vibrant world to keep playing while a bigger thing waits at the cliff. The Construction surface is warm and hand-drawn; Reality runs underneath it and presses through when the rally pauses long enough to listen.

The game has to land for both readers. A player who never thinks about the narrative should still want the window on their desktop. A player who notices the names, the descriptions, the weight that a pong game has not earned, gets the second layer. Neither layer punishes the other.

This folder is the design thinking behind the game, organised by the people who do the work.

## Where to start

If you are an **artist** picking up a brief, read [Art / Bible](art/bible.md) first, then [Direction](art/direction.md) and [Inspirations](art/inspirations.md). The bible is the source of truth; everything else explains why it says what it says.

If you are an **engineer** new to the codebase, read [North Star](north-star.md) for the shape of the game, [Tech-art / INDEX](tech-art/INDEX.md) for the rendering side, and the active phase folder ([01-prototype/](01-prototype/INDEX.md) at the moment) for what the team is building this cycle.

If you are a **writer** working on copy, beats, or character voice, read [Narrative / Outline](narrative/outline.md) for the story, [Narrative / Discipline](narrative/discipline.md) for craft notes, and [Research / STYLE](research/STYLE.md) for the prose voice the project holds itself to.

If you are one of **Josh's collaborators** looking for canon on a specific point, the discipline folder is the answer. Art questions land in `art/`, story questions in `narrative/`, pipeline questions in `tech-art/`. The phase folders are working drafts; the discipline folders are what those drafts mature into.

If you are an **open-source visitor**, [The Case for Open Development](research/the-case-for-open-development.md) is the project's published essay on why the work is in the open. [CONTRIBUTING.md](https://github.com/Shuck-Games/volley/blob/main/CONTRIBUTING.md) at the repo root is the practical entry point.

## How the docs are organised

Two kinds of folder.

**Discipline folders** hold canonical work, owned by the people who do that discipline. `art/`, `narrative/`, `tech-art/`, `ai/`, `process/`, `research/`, `characters/`, `concept/`. When something here changes, the next brief and the next ticket pick the change up.

**Phase folders** hold drafts and decisions tied to a stage of the game's life. `01-prototype/`, `02-alpha/`, `03-beta/`, `04-content/`. Work starts in the active phase folder, gets argued through, and settles into the relevant discipline folder when it earns canon.

The two-folder layout is the navigation: discipline tells you *what kind of doc*, phase tells you *what era it speaks to*.

## Discipline

### Art

| Doc | Purpose |
|---|---|
| [Bible](art/bible.md) | Canonical rules: palette, silhouette, line, mood, era, treatment. Source of truth for visual direction. |
| [Direction](art/direction.md) | The themes the bible distils. The narrative layer behind the rules. |
| [Inspirations](art/inspirations.md) | Works Volley! has looked at, with attribution. |
| [Tech Pipeline](art/tech-pipeline.md) | How the style is implemented in Godot: rendering, assets, register shifts. |
| [Character Lighting](art/character-lighting.md) | Dynamic light-state pipeline for characters across venues. |

### Narrative

| Doc | Purpose |
|---|---|
| [Outline](narrative/outline.md) | The story beats, in order. Construction, the break, Reconstruction, the choice at the cliff. |
| [Discipline](narrative/discipline.md) | Writing craft notes for the project: voice, beats, register shifts. |

### Tech-art

| Doc | Purpose |
|---|---|
| [INDEX](tech-art/INDEX.md) | The discipline overview: pipeline, scope, current spikes. |
| [Grading](tech-art/grading.md) | LUT pipeline for the two-style grade between Construction and Reality. |

### Process

| Doc | Purpose |
|---|---|
| [Ticket Writing](process/ticket-writing.md) | How issues get written so a stranger can pick them up cold. |
| [Labels](process/labels.md) | The label taxonomy and what each label changes about a ticket's shape. |

### Research

| Doc | Purpose |
|---|---|
| [STYLE](research/STYLE.md) | The prose voice this project holds itself to. Read once before writing long-form. |
| [The Case for Open Development](research/the-case-for-open-development.md) | The published essay: why open development is the most reliable practice for a new indie to be seen. |
| [Open Development Plan](research/open-development-plan.md) | The internal plan that seeded the essay. |
| [Visual Positioning](research/visual-positioning.md) | Where Volley! sits visually among idle, desktop, and sport games. |
| [Early Clone Games](research/early-clone-games.md) | Why Breakout's clone lineage outlasted Pong's. |
| [Game Structure References](research/game-structure-references.md) | Structural reference points for the loop and the story. |

### Characters

| Doc | Purpose |
|---|---|
| [Protagonist](characters/protagonist.md) | Who the player is playing as, and what the partners are to them. |

### Concept

The concept folder runs from [00-three-styles](concept/00-three-styles.md) through [05-postgame](concept/05-postgame.md). Earliest framing of the two-style world, the rally, the partners, the break, the reconstruction, and what the game looks like once the credits have rolled.

### AI

| Doc | Purpose |
|---|---|
| [Swarm Architecture](ai/swarm-architecture.md) | The agent system that helps build the game: Gru-and-minions, two pools, session tiers, PR verdict flow. |

The [open-development essay](research/the-case-for-open-development.md) sits in `research/` but speaks to the same surface: what stays human in the work as AI absorbs the boilerplate.

## Phase

| Phase | Folder | What lives here now |
|---|---|---|
| Prototype | [01-prototype/](01-prototype/INDEX.md) | The public itch.io demo. Active drafts that have not yet matured into discipline canon. |
| Alpha | [02-alpha/](02-alpha/INDEX.md) | Construction era content-complete; the break designed. |
| Beta | [03-beta/](03-beta/INDEX.md) | Reconstruction and both endings playable. |
| Content Updates | [04-content/](04-content/INDEX.md) | Supplementary content past the main arc. |

Drafts start in the active phase folder, settle into the discipline folder when they earn canon, and the phase folder keeps the working history.

## Top-level

| Doc | Purpose |
|---|---|
| [North Star](north-star.md) | What the game is, who it's for, what it asks of the player. |
| [Roadmap](roadmap.md) | The five phases at a glance. |
