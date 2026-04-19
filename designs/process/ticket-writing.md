# Ticket Writing Guide

How we write issues so anyone can pick up work without a briefing call: team members and open-source contributors arriving cold from a link. The goal is tickets that describe outcomes clearly enough for a stranger to make good decisions, without locking them into one solution.

Shuck plans internally in Linear and mirrors the public work to GitHub issues. Open-source contributors work through GitHub, which has everything needed to pick up and ship a ticket. The "For contributors" section below is the short version for contributors.

The one-page cheat sheet for filing tickets lives in `CLAUDE.md` under "Linear Ticket Writing Guidelines".

**Stranger test.** Before filing, imagine the ticket is the only context a first-time contributor will have. They have the repo, the design docs, and the ticket. They cannot ask you a question and get an answer within the hour. Can they tell what "done" looks like, what is in scope, and what is out of scope? If not, the ticket is not ready.

---

## Reading tickets

If you have landed here as a contributor, welcome. This section covers how to read a ticket so you can dive in with confidence. The practical side, picking up a ticket, running the project, submitting a PR, lives in [`CONTRIBUTING.md`](../../CONTRIBUTING.md).

**Ticket shape.** Every ticket carries a label from the [intent taxonomy](labels.md): `feature`, `spike`, `bug`, `study`, `asset`, `revision`, `concept`, `cue`, `rework`, `voice`, `draft`, `rewrite`, `discovery`, `tune`, or `sfx`. The label tells you what kind of output is expected and which discipline the work belongs to. The body tells you what done looks like. If the label and the body disagree, ask in the thread; the body usually wins.

**Acceptance criteria are the contract.** If the AC is met, the ticket is done. If any of it is unclear, ask in the ticket thread before opening a PR; we would rather answer a question than ask for a rework.

**Good first issues.** The `good first issue` label is community-driven. If you pick up a ticket that turned out to be small, well-scoped, and approachable for a newcomer, add the label on your way out so the next person can find it. Any unassigned ticket is open for contribution regardless.

---

## Principles

Applies to every ticket, every discipline.

**Write outcomes, not tasks.** A ticket describes what the system, player, or asset will look like when the work is done. It does not describe the steps or the files. Inspired by Mike Cohn's reminder that stories named "update the database" are tasks in disguise.

**Acceptance criteria are testable observations.** Each line is something a reviewer can check by looking at the game, the asset, or the player's behaviour. Avoid method names, file paths, and references to current code. Someone picking up the ticket a month later, or a contributor who has never opened the project, should still be able to tell when it is done.

**Link the context a stranger needs.** Link the design doc, the [art bible](https://github.com/J-Melon/volley-vendetta/blob/main/designs/art/bible.md), the parent artifact, the bug's originating feature. Do not say "see the kit design"; paste an absolute GitHub URL like `https://github.com/J-Melon/volley-vendetta/blob/main/designs/01-prototype/08-kit.md`. Absolute URLs survive both Linear and GitHub; repo-relative paths only resolve on GitHub and break when the ticket mirrors across.

**Name the scope boundary.** A good ticket says what is in and what is out. "Walk-off, equip pose, walk-on. Not in scope: the drag-and-drop tech (#141), the character concepts (#95)." Scope boundaries protect a new contributor from accidentally expanding the work and from cutting too deep. Use `#N` GitHub issue references when cross-linking tickets; GitHub renders them as links, and Linear's GitHub integration resolves them when the ticket mirrors.

**Leave room for conversation, but publish the conversation.** Borrowed from Ron Jeffries' Three Cs (card, conversation, confirmation): the ticket is a promise of a conversation. For a contributor, the conversation has to happen in the ticket thread or the linked design doc; verbal context does not reach them. Over-specifying still kills iteration, so leave room, and document decisions in comments as they happen.

**Titles are short and punchy.** Symptoms, qualifiers, and context belong in the body. "Timeout and Equip" reads better than "Implement the timeout system so the main character can equip items".

**INVEST as a sanity check.** Independent, Negotiable, Valuable, Estimable, Small, Testable (Bill Wake, 2003). Use it to spot tickets that should be split, merged, or rewritten. Independence matters extra for open-source: a contributor should be able to ship the ticket without a long chain of dependencies pulling them into unrelated systems.

**The `good first issue` label is community-driven.** Contributors add it themselves to tickets that turned out to be approachable for newcomers. Maintainers do not curate it. Any unassigned ticket is implicitly open for contribution.

---

## Three tiers of intent

Our label taxonomy follows a pattern across most disciplines:

|           | Explore               | Produce                 | Evolve                |
| --------- | --------------------- | ----------------------- | --------------------- |
| tech      | spike                 | feature                 | (bug restores)        |
| art       | study                 | asset                   | revision              |
| music     | concept               | cue                     | rework                |
| writing   | voice                 | draft                   | rewrite               |
| design    | discovery             | -                       | tune                  |
| sfx       | -                     | sfx                     | -                     |

Three intents, plus `bug` as its own shape.

### Explore

The question comes first, the output second. An explore ticket answers a question: can we, how would we, what would this feel like. The artifact (a spike writeup, a concept sketch, a voice sample, a discovery prototype) is evidence of the answer, not the point.

"Done" means the question is answered and a decision is documented. Coverage matters more than polish. A discovery prototype that kills three options and points at a fourth is a win.

Timebox the work. Kent Beck's original spike, in *Extreme Programming Explained* (1999), is time-bounded investigation producing knowledge, not shippable code. Same applies to studies, concepts, voice explorations.

### Produce

A concrete, finished thing enters the game: a feature, an asset, a cue, a draft, an sfx. Acceptance criteria describe the shipped artifact's observable behaviour or qualities.

Clinton Keith (*Agile Game Development with Scrum*, 2nd ed. 2020) points out that game production tickets must carry experiential criteria alongside functional ones. A feature that runs and compiles can still fail review because the feel is off. Leave room for that: "the rally feels continuous", "the walk-off reads as stepping out of play", "the cue supports the tension without drawing attention".

### Evolve

The existing thing changes. Revision, rework, rewrite, tune. These tickets anchor to a parent artifact and describe the delta: what will change, and just as importantly, what stays.

Ryan Singer's *Shape Up* (Basecamp, 2019) argues polish and iteration work needs different framing than new-appetite work. Evolve tickets are short, scoped, and reference the specific note or observation driving the change.

### Bug

Separate shape. A bug is a system that has drifted from intended behaviour. The ticket restores intent.

Repro steps lead everything else. Simon Tatham (*How to Report Bugs Effectively*, 1999) and Joel Spolsky (*Painless Bug Tracking*, 2000) agree: without a reliable reproduction path, a bug is not actionable. State what should happen, then what actually happens, then the environment in which you saw it.

Acceptance criteria confirm the bug is gone and nothing adjacent regressed.

---

## By discipline

### Tech

Labels: `spike`, `feature`, `bug`.

**Spike** (explore). Question-led. Output is a written recommendation: option A vs B, with reasoning, risks, and a suggested path. Spikes answer "can we" or "how would we" before a feature is written against them. Keep them small; if a spike looks large, it probably contains a feature underneath.

**Feature** (produce). Most features at Shuck are System Stories because they describe internal capability. Player-facing interaction uses User Story form. Either way, AC describes observable system or player outcomes. Insomniac's engineering practice (Mike Acton, GDC 2014–2019) adds target platform and frame-time budget to tickets touching the runtime; adopt the same discipline when perf is load-bearing.

**Bug** (restore). The Bug format in CLAUDE.md is the full template. Regressions block their originating feature.

### Art

Labels: `study`, `asset`, `revision`.

The discipline-level reference is the [art bible](https://github.com/J-Melon/volley-vendetta/blob/main/designs/art/bible.md): a living document of silhouette rules, palette, line, mood, era, faction. Tickets lean on the bible rather than repeating it. Chris Solarski (*Drawing Basics and Video Game Art*, 2012) and Riot's public art team posts set the pattern.

**Study** (explore). Concept work. Carries: function in world, silhouette and read at distance, mood words, reference board, constraints (palette band, era, faction). "Done" is when the study answers the direction question the art director asked, per Samwise Didier (Blizzard, GDC) and Jaime Jones (Bungie, GDC 2018). Polish is not the point; coverage of options is.

**Asset** (produce). Finished visual element for integration. Adds the specs a study deliberately omits: rig compatibility, LOD count, naming, engine slot. "Done" is in-engine integration pass, not file delivery. An asset sitting in a folder that isn't loaded does not count.

**Revision** (evolve). References the parent asset explicitly and names the director note driving the change. The Double Fine *Massive Chalice* postmortem is instructive: revision tickets that don't link the note drift.

### Music

Labels: `concept`, `cue`, `rework`.

Winifred Phillips (*A Composer's Guide to Game Music*, MIT Press, 2014) gives the cue-brief taxonomy used across the industry. Austin Wintory (GDC 2013, *Journey*) and Jesper Kyd emphasise that cues are briefed by player state, not visual scene.

**Concept** (explore). Mood-board plus a one-minute sketch. Carries function, mood, reference tracks, instrumentation hints. Does not carry loop points, stems, or middleware integration. "Done" is a direction the composer and designer both recognise.

**Cue** (produce). Fully specced: function (combat, explore, menu, stinger), mood, instrumentation, reference, duration or loop length, interactive structure (vertical layers, horizontal transitions, stingers), tempo and key constraints where stingers must match. Middleware event names and RTPC parameters where relevant. Stems delivered as agreed.

**Rework** (evolve). The original cue plus a specific note, plus the constraints that stay fixed. A rework ticket with no parent cue id is a draft ticket in disguise.

### Writing

Labels: `voice`, `draft`, `rewrite`.

Hannah Nicklin (*Writing for Games*, 2022) frames voice work as bible entries distinct from content, which matches our three-tier split. Emily Short's blog and Steve Ince (*Writing for Video Games*, 2006) are the other primary references.

**Voice** (explore). A bible entry for a character or register: vocabulary, rhythm, taboos, sample lines. "Done" is an approved entry the draft work can cite. No scene content lives here.

**Draft** (produce). A scene, barks, UI copy, a codex entry. Carries scene goal, required information beats (what must the player know after this), word or line budget, branch count, barks needed. Ince's 2006 clause, "what must the player know after this scene", is the most useful AC anchor.

**Rewrite** (evolve). Tied to a systemic change (new companion, cut quest, tone shift) per Obsidian and Larian practice, not line polish. Line polish is draft work on an existing scene.

### Design

Labels: `discovery`, `tune`.

Jesse Schell (*The Art of Game Design*, 3rd ed. 2019) and Raph Koster (*A Theory of Fun*, 2004) frame the split: discovery answers an open question, tuning refines an established system against a target.

**Discovery** (explore). Open direction question. Output is a decision plus a killed option. Jonathan Blow and Jenova Chen push "playable question" as the artifact: a prototype that lets the team feel the answer, not read it. "Done" is the question answered.

**Tune** (evolve). Measurable target (time to kill, session length, win-rate band, rally length) and the knobs in scope. "Done" is the metric sitting in band across playtests, not that values changed. Per Keith (2020), without a target tuning tickets never close.

Design has no `produce` label because design output is always a spec that tech, art, or writing then produces. A design decision ships through another discipline's ticket.

### SFX

Label: `sfx`.

Ariel Gross (*The Audio Manager's Handbook*, 2017) is the canonical reference. Consensus on SFX briefs is tight: the industry agrees on the fields.

A SFX brief carries trigger event, function (feedback, ambience, UI, diegetic), emotional tone, reference, variation count, length, priority and voice-stealing rules, and middleware event name. Akash Thakkar (GDC 2017, 2019) adds "what does the player need to know from this sound" as the function clause. Joanna Fang (Naughty Dog, GDC 2018) stresses physical material, surface, and force for diegetic sfx.

There is no `explore` or `evolve` label for sfx at Shuck. Exploration folds into variation count or a separate prototype pass.

---

## Templates

### User Story (player-facing feature, voice or draft when content is player-facing)

```
As a [role]
I want [capability]
So that [benefit]

**Acceptance Criteria:**
- [ ] ...
```

### System Story (internal feature, study, asset, concept, cue, discovery, tune, sfx)

```
[ACTION-VERB] [statement of what the system/asset does]
So that [benefit or reason]

**Acceptance Criteria:**
- [ ] ...
```

### Revision / Rework / Rewrite / Tune (evolve)

```
EVOLVE [parent artifact] so that [new outcome]
Per [note or observation driving the change]

**What changes:**
- ...

**What stays:**
- ...

**Acceptance Criteria:**
- [ ] ...
```

### Spike

```
SPIKE: [question]
So that [downstream decision that depends on the answer]

**Open questions:**
* ...

**Deliverable:** written recommendation covering the open questions.

**Timebox:** 1 to 2 days.
```

### Bug

```
**Summary:** [One-line description of the bug]

**Steps to Reproduce:**
1.
2.
3.

**Expected Behavior:**
[What should happen]

**Actual Behavior:**
[What actually happens]

**Environment:**
- Scene: [e.g. res://scenes/GameMain.tscn]
- Conditions: [e.g. "only when upgrade purchased", "after round 2"]

**Acceptance Criteria:**
- [ ] [Specific, testable condition that confirms the bug is fixed]
- [ ] No regression in related systems
```

---

## Writing for open-source contributors

The project is developed in the open. Tickets are public, and strangers land on them from search engines, social posts, or the "good first issue" feed. A few extra habits keep those tickets useful.

**Assume no context at all.** The contributor has not read the design docs, has not played the game, does not know what a "timeout" means in our vocabulary. Link and define, briefly, anything that would otherwise require tribal knowledge. The first sentence of the ticket body should tell a stranger what this piece of the game is.

**State the discipline and the label plainly.** "This is an art asset ticket. We need a 2D sprite sheet." or "This is a tech feature ticket. We need a new signal wired into the game loop." Labels are data; the body tells a human what the labels mean for them.

**Give entry points into the codebase.** Not "implement this in the shop system", but "the shop system lives in `scenes/shop/`; the current entry point is `scripts/shop/shop.gd`. You will most likely touch these files, though you are welcome to restructure." Contributors save hours if the starting path is named.

**Make the merge criteria concrete.** Beyond acceptance criteria, what does a reviewer check? Tests green, lint green, manual playtest of the affected scene, screenshots for UI changes. State it if the ticket has anything beyond the project defaults in [`CONTRIBUTING.md`](../../CONTRIBUTING.md).

**Close the loop in public.** When a ticket lands, the PR link, the release it shipped in, and a thank-you in the ticket thread make the next contributor more likely to engage. A closed ticket with no trail is demotivating.

---

## GitHub issue reference

For open-source contributors, the canonical view of a ticket is on GitHub. Here is what GitHub issues support and how we use each feature.

**Title and body.** The body is Markdown. Images, code blocks, links, and headings all render. Keep the title short; put detail in the body.

**Labels.** Applied per ticket. Our set is listed in "By discipline" below. Each label's description leads with its discipline group (`tech:`, `art:`, `music:`, `writing:`, `design:`, `audio:`) so the family reads at a glance. `good first issue` is applied by contributors themselves to tickets that turned out to be approachable.

**Assignees.** A ticket with an assignee is being worked on. An unassigned ticket is open for anyone to claim by commenting. Self-assignment works if you have push access; otherwise comment and a maintainer will assign you.

**Milestones.** We use milestones to group tickets by release milestone: Prototype, Alpha, Beta, Polish, v1, Future Updates.

**Linked pull requests.** Reference the issue in your PR with `closes #123` or `fixes #123` in the PR body. GitHub will link them and close the issue on merge. Cross-reference other issues with `#123` anywhere in the body or comments to create a backlink.

**Task lists.** Acceptance criteria use Markdown task list syntax (`- [ ]`). GitHub renders these as checkboxes and tracks progress in the issue list.

**Mentions.** `@username` notifies a contributor. Use sparingly; prefer letting the ticket speak for itself.

**Issue templates.** New issues filed on GitHub use our templates from `.github/ISSUE_TEMPLATE/`, one per intent (feature, bug, spike, and so on), each matching the shapes in "Templates" below.

**Reactions and comments.** Comments capture conversation and decisions. Reactions (`+1`, eyes, heart) signal interest without adding noise. A ticket thread is the durable record of how the work was scoped.

---

## Linear conventions

Internal to Shuck. Covers cycles, estimates, priority, and typed relationships that Shuck tracks alongside the public GitHub view.

**New tickets go to Backlog, no cycle.** Josh promotes tickets to Ready and adds them to cycles. Triage is for external/incoming tickets only, not for our own work.

**Labels by discipline.** Pick the most specific label that fits the intent and discipline. If in doubt between `feature` and `spike`, ask whether there is a committed output (feature) or an open question (spike). Between `asset` and `revision`, ask whether the thing exists yet.

**Fibonacci estimates.** 1, 2, 3, 5, 8, 13, 21. Bugs are 0. Spikes are 1. Stories stay unpointed until Josh sizes them.

**Blocks, not relatedTo.** Regressions block their feature ticket. Foundation tickets (style guides, pipelines, specs, spikes) block the asset, integration, and implementation work that depends on them. A ticket linked only with relatedTo rarely affects scheduling.

**Confirm before filing.** Draft the ticket, list candidates, wait for approval before creating in Linear. Don't file proactively to close perceived gaps; only file when the cycle needs the work.

---

## Sources

- Bill Wake, INVEST criteria, *XP123*, 2003.
- Ron Jeffries, Three Cs, 2001.
- Mike Cohn, *User Stories Applied*, 2004.
- Kent Beck, *Extreme Programming Explained*, 1999.
- Simon Tatham, *How to Report Bugs Effectively*, 1999.
- Joel Spolsky, *Painless Bug Tracking*, 2000.
- Clinton Keith, *Agile Game Development with Scrum*, 2nd ed. 2020.
- Ryan Singer, *Shape Up*, Basecamp, 2019.
- Chris Solarski, *Drawing Basics and Video Game Art*, 2012.
- Winifred Phillips, *A Composer's Guide to Game Music*, MIT Press, 2014.
- Austin Wintory, GDC 2013.
- Hannah Nicklin, *Writing for Games*, 2022.
- Steve Ince, *Writing for Video Games*, 2006.
- Jesse Schell, *The Art of Game Design*, 3rd ed. 2019.
- Raph Koster, *A Theory of Fun*, 2004.
- Ariel Gross, *The Audio Manager's Handbook*, 2017.
- Akash Thakkar, GDC 2017 and 2019.
- Joanna Fang, GDC 2018.
