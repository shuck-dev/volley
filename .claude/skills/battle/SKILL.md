---
name: battle
description: Dispatcher-side rules for battling a challenge: the end-to-end review loop. Ground-read review state, dispatch at least one independent reviewer (more by scope), converge without churn, resolve the verdict against the issue's AC, fire the bot review, then push and move on. Read when battling any PR. The owning memory is feedback_battle_review_process; the challenge body shape is the `pr` skill; the per-reviewer contract is the `reviewers` skill.
---

# Battling a challenge

The organiser's side of a review battle. A *challenge* is the PR (see [`pr`](../pr/SKILL.md) for its body shape); a *battle* is the review run against it. This skill is what Gru reads to run that pass; it renders the memory branch [[feedback_battle_review_process]] under [[trunk_dev_cycle]], which is the authority. The reviewer agent's own contract (posture, finding form, inline discipline) lives in [`reviewers`](../reviewers/SKILL.md); brief each reviewer to read it.

A battle is a confidence pass over a shipped challenge, not an exhaustive audit. It is minion work, dispatched by default rather than run in-thread. The depth scales with the diff, but the floor never drops to zero.

## The floor: one independent reviewer, always

Every PR gets at least one independent reviewer before it is reviewed. "No fan-out" and "spot-check" mean one reviewer at the right depth instead of a full panel, not zero reviewers. Reading my own diff and finding it correct is not a review: I wrote it, so I find it coherent, which is [[feedback_self_judgment_is_coherence_not_accuracy]] applied to my own change. The dispatcher reading the diff first is due diligence before handoff, not the review.

The tell, and it fires often: I am about to tell Josh a PR is "ready" or "yours to merge" having only read it myself. That PR has had zero reviews. Dispatch one reviewer first. Pick the single lens the diff calls for (devils-advocate for a rule-bearing doc, code-quality for a small code change, docs-and-writing for prose) and dispatch it. Fan to several specialists only when the diff's scope justifies it; the minimum is one, not zero.

## The loop

1. **Ground-read before dispatch, review state included.** The pre-battle `gh` read covers `state`, `mergeable`, HEAD, checks AND `reviewDecision` plus the per-PR reviews (`gh api .../pulls/<n>/reviews`), not just CI. Skipping the reviews means battling a PR that may already carry an approval; stale approvals do not auto-dismiss, so a PR can show an active bot APPROVE on an old SHA. Know the review state before re-treading it. Then dispatch reviewers scoped to the diff's lanes, always `run_in_background: true`, against the live HEAD. The path → specialist map is in [`reviewers`](../reviewers/SKILL.md). Findings go inline.

2. **Converge, do not churn.** After a round or two with findings addressed and CI green, another battle surfaces nothing new; it just spins. Do not re-battle a converged PR; that is churn dressed as diligence. Once converged, the bottleneck is a decision, not more review signal.

3. **Resolve the verdict yourself, against the AC.** The organiser resolves reviewer consensus into approve / request-changes / comment. This is mine to call as advisor: do NOT ask permission to fire the bot; asking defeats the automation. Pause only if the verdict itself is genuinely undecided. Resolve it from the inline PR threads, the durable record, not from the agents' direct reports: `gh api .../pulls/<n>/comments` and read the live threads. The report-back is for what a reviewer cannot anchor inline (off-diff findings, confidence, the failure modes it cleared).

   **Before approving, check the PR meets its issue's AC**, not merely that its commits are clean. A bug found later that means the PR can't meet its own AC is not a follow-up ticket; it is unfinished work that folds into the same PR, and it means an earlier APPROVE was premature. An approve means the change was verified against its AC; replying to comments alone does not earn it. A reviewer who approves while flagging a global-state or production-vs-test caveat is reporting a block-worthy concern; weigh it as one.

4. **Fire the bot review.** `gh workflow run bot-review.yml -f pr=N -f event=APPROVE|REQUEST_CHANGES|COMMENT -f body="..."`. It posts as a distinct bot identity, so its APPROVE is a real approving review, not self-approval (the bot did not author the PR). Trigger is `workflow_dispatch` only; CI never runs Claude on `pull_request` events (injection surface). The body highlights the individual reviewer findings (attributed, mine if any), not an aggregated synthesis paragraph; verdict on its own line; under 400 chars; omit any line that has nothing. The body template lives in [`reviewers`](../reviewers/SKILL.md), "Synthesis body (organiser)".

5. **Push and move on; CI calls back only on failure.** After a push, attention goes to the next piece of work. CI runs itself, and the merge queue plus the maintainer own the path to green; a passing or pending run is theirs. A FAILURE is the one CI event that is mine, acted on when it lands. Read CI state once when a claim needs grounding, then return to the work. No watching a pending run.

6. **The decision is Josh's.** He merges if he agrees with the bot's verdict. The bot APPROVE is not the approval that ships code; the merge click is. No auto-merge.

## Re-battle scope

Re-battle only when a push materially changes scope (a real feature change, not a mechanical fix or a type narrow), or when Josh asks. A converged PR with only mechanical follow-ups is a silent pass, not another round.

When you do re-battle, scope it to the NEW change, not the whole PR: choose reviewers by what the new commit touches (drop lenses whose surface didn't change, e.g. save-format-warden when no persisted shape moved; add one if the new commit enters its lane), and point each at the new commit's diff range (`git diff <prev>..<new>`), not `main...HEAD`. Re-reviewing already-cleared parts is the same churn. A push that invalidates the prior round's synthesis verdict earns a fresh review.

## Design and docs PRs battle on a different axis

A code PR battles its lanes (code-quality, signals-lifecycle, save-format, etc.). A design PR (a `.md` that argues a design, not just prose) battles the IDEA: devils-advocate scoped to the design's claims is a REQUIRED lane, not the optional fresh-eyes pass, alongside docs-and-writing (STYLE) and repetition-reviewer (cross-doc dup). That battle is GENERATIVE, not a confidence pass: the right outcome is often that the design CHANGES between rounds. Re-battle a design PR after a substantive rewrite (discovery-rewrites-the-spec), not after a typo fix. The severity rule still governs the verdict: only an `issue:` blocks; `nitpick:`/`suggestion:` ride along and never force a re-battle.

## Consensus on disagreement

When two minions reach opposite conclusions on the same evidence (reviewer approves while battler blocks, two reviewers split), don't pick a side. Dispatch two more independent agents on the same question, briefed not to read each other's reports. Whichever side reaches three votes wins. Surface the consensus to Josh with the evidence each agent cited. If it stays split 2-2, the question isn't decidable from the evidence at hand; flag for Josh and don't merge.
