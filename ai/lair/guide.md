# The Lair: a guide to how Volley gets made

## What the Lair is

The Lair is Volley!'s operational base. It holds the repo docs, the agent infrastructure, and the scripts and workflows that let two weeks of work run without reinventing the wheel each time. If a rule is worth keeping, it lives in the Lair.

The Lair sits inside the Anti-Villain League, which is the broader circle around the project: Josh, the regular crew, and every contributor who turns up to help.

This page is the internal guide. It names the crew, walks through a cycle of work, and gathers the vocabulary in one place at the end. Read it once and you will recognise everyone.

## What happens here

Two weeks of work at the Lair looks like this. Josh decides what matters next. A plan for the cycle gets assembled. The work is split across specialist AI helpers, one per trade, who are dispatched one task at a time and who we call minions. The main Claude thread coordinates them. When a batch of work is ready, it goes through review, then through playtest, then out to the public as a release.

The names for each of those beats get introduced below in the order you meet them.

## Director Josh

Josh Hartley. The human. Josh directs the game: he sets priorities, approves designs, and signs off releases. The crew does the work; Josh says what the work is for and whether it is ready to ship.

## Gru, the field lead

Gru is the main Claude thread, the coordinator on shift. Gru reads the briefing for the day, picks which minions to dispatch, arranges the work so parallel hands do not trip over each other, and reports back when the round settles. The job is coordination, not code.

## The minions

Minions are the specialist AI helpers, dispatched one per task. Each has a trade: code quality, GDScript conventions, signals, scene structure, docs, CI, test coverage, save format, supply chain, and more. A minion joins a round of work, does its trade, files its report, and steps back. Under the hood they are sub-agents; in conversation we call them minions.

## Lucy and Nefario

Two supporting layers keep Gru and the minions current.

**Lucy** is the continuity layer: the long-term notes and conventions the crew draws on. In practical terms, that is the skills library, the memory store, the top-level `CLAUDE.md`, and everything under `ai/`. Every fresh Gru session opens with Lucy's briefing on what is in flight, what Josh decided recently, and what the Lair currently allows.

**Nefario** is the tool layer: the instruments the minions use to get anything done. In practical terms, that is GodotIQ (the Godot-aware tooling), the MCP servers, and the file and shell and web tools (Bash, Read, Write, WebSearch, WebFetch). Nefario hands each minion the right instrument for its trade and keeps the workshop in working order.

## The cycle

Each cycle is two weeks. The beats are the same every time.

**Dossier.** Before the cycle opens, Josh and Gru assemble the Dossier: the issues ready for the upcoming cycle, estimated, labelled, linked to their designs. A Dossier is what turns Vault into a plan.

**Mission briefing.** Before each mission inside the cycle, Gru writes a short briefing: which issues are in scope, which minions are cast, and the deadline. One paragraph is usually enough. The briefing is what the minions read first. A mission is a bundle of issues dispatched as one coordinated push.

**Dandori.** A verb, borrowed from Shigeru Miyamoto, who uses it to mean good planning. To dandori is to plan the work so parallel hands can close it without tripping over each other. "Gru dandoris the review round" means Gru reads the diff, partitions it by reviewer scope, and dispatches the right minions at once.

**Dandori Challenge.** A pull request. A Challenge is where minions close out a mission together. The Challenge opens when the PR opens; it ends when the PR merges.

**Dandori Battle.** The adversarial review round inside the Challenge. Reviewer minions post their verdicts, blocks supersede approves, authors revise, and the Battle resolves when the diff is clean and Josh signs off.

**The Carnival.** The build as a playable experience. Every release candidate is its own Carnival. The playtesters ride it first.

**The Heist.** The release operation. Named after Gru's moon heist, with the polarity flipped: this one gives the prize to the world instead of taking it.

**The Return.** The release moment itself. Named for the end of *Despicable Me 1*, when Gru returns the moon. It is the only heist that ends by handing the loot over.

**Mission debrief.** After a mission closes, the crew debriefs. What shipped, what surprised, what to do differently.

**Cycle retro.** At the end of the cycle, a retro. The word is already cross-industry and nobody needs a new one.

## The playtesters

Margo, Edith, and Agnes ride every Carnival before it leaves the Lair. The Return waits on their nod.

They have their own ways of playing. **Margo** is the analytical one: she reads the systems, notices the edges, and writes up what the numbers feel like in the hand. **Edith** tries to break it: she holds the controller wrong on purpose, mashes inputs, and finds the rough corner you forgot to round off. **Agnes** is the vibe check: she plays the way a first-time player would, and tells you whether the thing is actually fun before any of the detail matters.

## The public

The players who get to play what the Return brings them. The reason any of this happens.

## The cast, in one glance

- **Director Josh.** Human. Directs the game.
- **Gru.** Main Claude thread. Coordinates the day's work.
- **Minions.** Specialist AI helpers, dispatched one per task.
- **Lucy.** Continuity layer: skills, memory, `CLAUDE.md`, `ai/` docs.
- **Nefario.** Tool layer: GodotIQ, MCP, Bash, Read, Write, WebSearch, WebFetch.
- **Margo, Edith, Agnes.** Playtesters. Analytical, break-it, vibe-check.
- **The public.** Players of the shipped game.

## Glossary

| Term | What it means |
|---|---|
| The Lair | Volley!'s operational base: agent infrastructure and repo docs. |
| Anti-Villain League | The broader circle around the project: crew and contributors. |
| Director Josh | Josh Hartley. Sets priorities, approves, signs off. |
| Gru | Main Claude thread. Field lead; coordinates, rarely codes. |
| Minions | Specialist AI helpers dispatched one per task. |
| Lucy | Continuity layer: skills, memory, `CLAUDE.md`, `ai/` docs. |
| Nefario | Tool layer: GodotIQ, MCP, Bash, Read, Write, WebSearch, WebFetch. |
| Margo, Edith, Agnes | Playtesters. Analytical, break-it, vibe-check. |
| The public | Players who get the shipped game. |
| Mission | A bundle of Linear issues dispatched as one coordinated push. |
| Dossier | Pre-cycle ritual: the issues readied for the upcoming cycle. |
| Mission briefing | Pre-mission ritual: scope, cast, deadline. |
| Dandori | Verb. Plan the work so parallel hands can close it cleanly. |
| Dandori Challenge | A pull request, seen from the mission side. |
| Dandori Battle | The adversarial review round inside a Dandori Challenge. |
| The Carnival | The build as a playable experience. Each RC is its own Carnival. |
| The Heist | The release operation. Inverted polarity: gives to the world. |
| The Return | The release moment itself. |
| Mission debrief | Post-mission retrospective. |
| Cycle retro | End-of-cycle reflection. |

Usage examples, so the words feel natural:

- "Gru dandoris the Muppets cycle Dossier before Tuesday."
- "SH-321 opened its Dandori Challenge this morning; Trillian and Marvin are in the Battle."
- "The Carnival on `rc-0.4` passed Margo's test. Edith is on it next."
- "The Return ships Monday if nothing blocks."
- "Nefario added a new MCP server; the minions pick it up next session."

## What stays the same

Three layers do not change under any of this. The Lair sits on top of them; it does not replace them.

**Linear.** Issues, cycles, states (Triage, Vault, Ready, Dispatched, Challenged, Completed), projects, labels. The Linear vocabulary is what every dashboard and API call already speaks.

**GitHub.** Pull requests, reviews, merges, tags, releases, branches. When Gru says "PR" it means pull request; when Gru says "Dandori Challenge" it means the same pull request from the mission side.

**Cycle names.** Every cycle spends its two weeks at the Lair under its own name. Right now the names march alphabetically through famous puppets. Future cycles may pick a different theme; what matters is the habit of naming each cycle, not the theme it happens to wear.

**Agent codenames.** Every minion gets a codename per work unit, rotated from a fixed pool: *Gravity Falls*, *Hitchhiker's Guide to the Galaxy*, *Oddworld*, *Omori*, *Outer Wilds* (Hearthians and Nomai), Volley!'s own cast (Martha and friends), and *Minions* too where a Minion-flavoured name fits the case. Trillian reviewing a PR is still Trillian; the role underneath is `code-quality` or whichever slot fits.
