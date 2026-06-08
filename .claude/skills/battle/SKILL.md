---
name: battle
description: Dispatcher-side rules for running a reviewer battle against a challenge: when it fires, scope-filtering reviewers by changed path, the design-PR required lane, one-round discipline, consensus on disagreement, and firing the synthesis verdict. Read when Josh asks for a battle. The challenge being battled is the `pr` skill; the per-reviewer contract is the `reviewers` skill.
---

# Running a battle

The organiser's side of a reviewer battle: the adversarial review pass against an open challenge. A *challenge* is the PR (see [`pr`](../pr/SKILL.md) for its body shape); a *battle* is the review run against it. This skill is what Gru reads to run that pass. The reviewer agent's own contract (posture, verdict shape, inline-finding discipline) lives in [`reviewers`](../reviewers/SKILL.md); brief each reviewer to read it. The memory branch for the whole loop is [[feedback_battle_review_process]] under [[trunk_dev_cycle]].

## When a battle fires

The default is no reviewer fan-out. The dispatcher spot-checks every diff (read it, run the suite, verify the behaviour holds) and that is the review for most increments: docs, renames, mechanical changes, small fixes. A big PR is one review surface, spot-checked once at the right depth, never re-battled per commit.

A reviewer battle runs only when Josh asks for one. When he does: scope-filter the diff by changed path and fan only the matching specialists (code-quality, gdscript-conventions, test-coverage on a GDScript diff; domain reviewers on the files they own). The full path → specialist map and the verdict contract live in [`reviewers`](../reviewers/SKILL.md). Battlers (devils-advocate, integration-scenario-author) fire alongside only when the battle is requested. Devils-advocate has Bash, so it posts its findings as inline review comments like any reviewer; brief it to do so, and do not tell it to reason from the diff text alone.

## Design-PR battles are generative

On a **design or spec doc** (a `designs/**` change that argues a design, not just prose), devils-advocate is a REQUIRED lane, not the optional fresh-eyes pass: fan it on the design's claims alongside docs-and-writing and repetition-reviewer. That battle is GENERATIVE, the right outcome is often that the design changes between rounds, so re-battle a design PR after a substantive rewrite (not after a typo fix). See [[feedback_battle_review_process]], the design-PR clause.

## One round, no stacked re-battles

Within a requested battle, run one round. Re-check a blocked finding with the one reviewer who raised it on the incremental, not a fresh fan-out; a clean incremental is a silent approve. Do not stack re-battles.

The dispatcher dispatches reviewers at explicit review moments (first open, author "ready for re-review"), not on every push. On re-run, pass each reviewer `last-approved-sha..current-head` as the incremental range; the prior approval stands for everything up to `<last-approved>`.

## Brief every reviewer the same line

Every reviewer dispatch brief restates one line: inline comments only, never the main thread, report your verdict to me. Reviewers apply no verdict label; they report their verdict to Gru and post findings inline.

## Fire the synthesis verdict

On every review round Gru posts one synthesis review via the `bot-review` workflow:

```bash
gh workflow run bot-review.yml -f pr=N -f event=APPROVE|REQUEST_CHANGES -f body="..."
```

The synthesis keys on SEVERITY, not finding-count: REQUEST_CHANGES only if some reviewer raised an unresolved `issue:`; APPROVE otherwise, even when reviewers posted `nitpick:`/`suggestion:`/`question:` inlines (those are folded or ignored by the author, never block, never force a re-battle). A pass whose only findings are non-blocking is an approve, not a block-fix-reapprove cycle.

The body template, its 300-char cap, and the clean-pass / block / re-review shapes live in [`reviewers`](../reviewers/SKILL.md), "Synthesis body (organiser)". Verify the inline findings landed before posting the synthesis verdict. The verdict does not gate merge: required checks are Tests and Lint, and the maintainer's manual merge is the approval; the bot review is the attributed agent verdict, not a required check.

## Consensus on disagreement

When two minions reach opposite conclusions on the same evidence (reviewer approves while battler blocks, two reviewers split, etc.), don't pick a side. Dispatch two more independent agents on the same question, briefed not to read each other's reports. Whichever side reaches three votes wins. Surface the consensus to Josh with the evidence each agent cited.

If consensus is still split 2-2, that's a sign the question itself isn't decidable from the evidence at hand; flag for Josh and don't merge.
