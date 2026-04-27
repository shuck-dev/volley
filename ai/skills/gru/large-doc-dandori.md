---
name: large-doc-dandori
description: Workflow for any large doc effort: new bible, rewrite of an existing big doc, or restructure across files. Plan structure first, dispatch multi-minion work against the plan, multi-lens review on the result.
---

# Large-doc dandori

Large docs and multi-file restructures need a planning beat before any prose lands. Otherwise the same paragraph gets moved twice, the same vocabulary needs sweeping six times, and review attention burns on files that should have been touched once.

**Trigger** by feel, not line count: if the table-of-contents is non-trivial, or the work spans more than one file, or the prose runs more than a few sections, this is large-doc work. Examples that qualify: a new bible, rewriting an existing big doc, splitting a doc into per-character files, killing a duplicate doc and rerouting inbound refs, sweeping a vocabulary change across the corpus.

Examples that do NOT qualify: a one-paragraph fix, a single-file polish pass, a typo sweep.

## The four beats

### 1. Plan beat (organiser + Josh)

Before any prose ships, sketch the structure. Land it in chat or a scratchpad.

For a single doc:
- Section list (proposed table of contents).
- What each section holds. One line each.
- What the doc explicitly does NOT hold (defers to which other doc).
- Cross-refs in and out.
- Voice rules in scope. Vocabulary to sweep. Banned phrases.

For a restructure across files:
- The end-state map. One line per file: what it holds, what it kills, what it renames, what it splits into, key cross-refs.
- The order of moves. Which PR does what, and the dependency between them.

Josh signs off on the structure. Changes during the work are explicit decisions, not drift.

### 2. Multi-minion author (parallel)

Dispatch minions per section or per file slice. Each gets:

- The full structure / map. So they know what's around them and don't restate canon that lives elsewhere.
- The voice rules. No madlibs, no vapid platitudes, no banned phrases, no register-as-tone, no "head tilted toward", no "small window on the desktop", etc.
- Their scope. Which section or file is theirs to author or move.
- The cross-refs they need to land. Which other docs they must link out to, and where.

Authoring minions return their draft to the organiser. The organiser stages, then dispatches review.

### 3. Multi-minion review (parallel)

Five lenses run on the result. Each lens is a separate dispatch; lenses run in parallel where the diff supports it.

| Lens | Agent | Job |
|---|---|---|
| Voice | docs-and-writing | Sense-pass for prose quality. Voice rules, banned phrases, em dashes, AI tells, closing morals. |
| Vocabulary | docs-and-writing (grep-driven dispatch) | Banned phrases and canon-stale terms across the diff. `register`-as-tone, `cozy` self-descriptor, era→acts, etc. |
| Repetition | repetition-reviewer | Does this restate canon that lives elsewhere? Cross-doc duplication finder. |
| Trim-verify | repetition-reviewer (sister lens) | If content was removed from a doc, did it land in the destination doc? Or was it lost? |
| Cross-ref hygiene | docs-and-writing | Links resolve. Each link points at the canonical home for what it's referencing. No dead refs to renamed or deleted files. |

Each reviewer follows `ai/skills/minions/reviewers.md` for verdict shape. Approves are silent label-only; blocks post inline review comments anchored to `path:line`, never on the main PR thread.

### 4. Synthesis (organiser)

Integrate review feedback. Push corrections. Final read against the structure plan to confirm the end-state matches what was signed off in beat 1. Any drift surfaces as an explicit revision to the plan, not a quiet rewrite.

## Discipline

- **No file gets touched twice for the same restructure.** If the plan needs a file's section moved AND that file's prose tightened, both happen in the same PR or the plan changes.
- **Trim-and-verify before push.** Every diff that removes canon names where the canon now lives. The organiser checks before staging.
- **The plan is the contract.** If the work reveals the plan is wrong, escalate to Josh and revise the plan. Don't drift the work.
- **Phase folders are not canon.** If the work surfaces phase-folder material that reads as canon, the move is to promote it to the right discipline folder, not to polish it in place.

## When to skip the dandori

A small fix to a large doc does not need the full beat. Examples:

- Fixing one banned phrase across two paragraphs.
- Rewording a single section.
- Repointing a stale link.

The trigger for the full workflow is the scope of the change, not the size of the file.

## Why this exists

Mission Page One (2026-04-26) shipped twelve PRs to restructure the artist canon. The bible was touched by six PRs, INDEX.md by six, the `register` vocabulary swept six times. The end-state structure emerged through the work instead of being mapped before the first PR. Each PR triggered conflicts in queued ones. The lesson: for large-doc work, the planning beat is cheaper than the churn it prevents.

The `feedback_restructure_end_state_map.md` memory captures the same lesson at the individual-behaviour level. This skill is the team-level workflow.
