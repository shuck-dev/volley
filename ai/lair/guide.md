# The Lair: a guide to how Volley gets made

Volley is built by a small crew with a big cast. Director Josh runs the operation from the Lair. Gru is the field lead. Lucy briefs him before every shift and keeps him current between them. Nefario arms the minions with the tools they need. The minions do the specialised work. The girls playtest the build before it ships. The public are the players who get what the crew returns to the world.

This page is the doorway. Read it once and you will recognise everyone by name.

## The cast

**Director Josh.** Josh Hartley, the human. Sets priorities, approves designs, signs off releases. Everything upstream of a dispatch is his call; everything downstream of a merge is his playtest.

**The Lair.** Volley's operational base: the repo docs, the agent infrastructure, the scripts and workflows that let the crew run a mission without reinventing the wheel each time. If a rule is worth keeping, it lives in the Lair.

**Gru.** The main Claude thread, field lead for the day. Gru reads the briefing, casts the minions, dispatches them in parallel, merges their work, and reports back. Gru writes almost no code directly. The job is coordination.

**Lucy.** The continuity layer: skills, memory, `CLAUDE.md`, `ai/` docs. Every fresh Gru session starts with Lucy walking through the current state of play, what's in flight, what Josh decided last week, what's allowed, what isn't. Without Lucy, Gru starts every shift from zero.

**Nefario.** The tool layer. GodotIQ, MCP servers, Bash, Read, Write, WebSearch, WebFetch. Nefario does not decide anything; Nefario hands out the right instrument for the job and keeps it in working order.

**The minions.** Specialist sub-agents, one per trade: code quality, GDScript conventions, signals, scene structure, docs, CI, test coverage, save format, supply chain, and the rest. A minion gets dispatched for a task, does that task, writes its report, and steps back.

**The girls.** Margo, Edith, and Agnes: the testers who play the build before it goes out. Release candidates pass through their hands.

**The public.** The players. The reason any of this happens.

## The cycle

Each cycle is a week. The beats are the same every time.

**Dossier.** Before the cycle opens, Josh and Gru assemble the Dossier: the issues ready for the upcoming cycle, estimated, labelled, linked to their designs. A Dossier is what turns Backlog into a plan.

**Mission briefing.** Before each mission inside the cycle, Gru writes a short briefing: which issues are in scope, which minions are cast, the ship-by. One paragraph is usually enough. The briefing is what the minions read first.

**Dandori.** A verb. To dandori is to arrange the work strategically so parallel hands can close it without tripping over each other. "Gru dandoris the review round" means Gru reads the diff, partitions it by reviewer scope, and fires off the right minions at once.

**Dandori Challenge.** A pull request. A time-boxed race where minions close out a mission together. The Challenge opens when the PR opens; it ends when the PR merges.

**Dandori Battle.** The adversarial review round inside the Challenge. Reviewers post their verdicts, blocks supersede approves, authors revise, the Battle resolves when the diff is clean and Josh signs off.

**The Carnival.** The build as a playable experience. Every release candidate is its own Carnival. The girls ride it first.

**The Heist.** The release operation. Named for Gru's moon heist, with the polarity flipped: this one gives the prize to the world instead of taking it.

**The Return.** The release moment itself. Named for the end of *Despicable Me 1*, when Gru returns the moon. It is the only heist that ends by handing the loot over.

**Mission debrief.** After a mission closes, the crew debriefs. What shipped, what surprised, what to do differently.

**Cycle retro.** At the end of the cycle, a retro. "Retro" stays as-is; the word is already cross-industry and nobody needs a new one.

## Glossary

| Term | What it means |
|---|---|
| Director Josh | Josh Hartley. Sets priorities, approves, signs off. |
| The Lair | Volley's operational base: agent infra and repo docs. |
| Gru | Main Claude thread. Field lead; coordinates, rarely codes. |
| Lucy | Skills, memory, `CLAUDE.md`, `ai/` docs. The continuity layer. |
| Nefario | Tool layer: GodotIQ, MCP, Bash, Read, Write, WebSearch, WebFetch. |
| Minions | Specialist sub-agents dispatched per task. |
| The girls | Margo, Edith, Agnes. Testers. |
| The public | Players who get the shipped game. |
| Mission | A bundle of Linear issues dispatched as one coordinated push. |
| Dossier | Pre-cycle ritual: the issues readied for the upcoming cycle. |
| Mission briefing | Pre-mission ritual: scope, cast, ship-by. |
| Dandori | Verb. Arrange the work strategically, dispatch in parallel. |
| Dandori Challenge | A PR. Time-boxed parallel-minion race to close a mission. |
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

**Linear.** Issues, cycles, states (Backlog, Icebox, Ready, In Progress, In Review, Done), projects, labels. The Linear vocabulary is what every dashboard and API call already speaks.

**GitHub.** Pull requests, reviews, merges, tags, releases, branches. When Gru says "PR" it means pull request; when Gru says "Dandori Challenge" it means the same pull request from the mission side.

**Cycle names.** Every cycle spends its week at the Lair under its own name. Right now the names march alphabetically through famous puppets. Future cycles may pick a different theme; what matters is the habit of naming each cycle, not the theme it happens to wear.

**Agent codenames.** Every minion gets a codename per work unit, rotated from a fixed pool: *Gravity Falls*, *Hitchhiker's Guide to the Galaxy*, *Oddworld*, *Omori*, *Outer Wilds* (Hearthians and Nomai), Volley's own cast (Martha and friends), and now *Minions* too where a Minion-flavoured name fits the case. Trillian reviewing a PR is still Trillian; the role underneath is `code-quality` or whichever slot fits.

## If you are new

Don't worry about memorising the cast. The crew briefs you when you arrive: Lucy hands over the current state of play, Gru points you at the mission, the minion whose slot matches your strength picks up its trade. Ask questions in the open. The Lair is built for it.

Welcome in.
