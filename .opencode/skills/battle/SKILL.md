---
name: battle
description: The PR review battle loop. Ground-read review state, fan independent reviewers, converge findings, resolve verdict from inline threads against the AC, fire the bot review, push and move on. Read when battling any PR.
---

# Battle

A *challenge* is the PR; a *battle* is the review run against it. The full memory is [[feedback_battle_review_process]] under [[trunk_dev_cycle]]; the per-reviewer contract is [[reviewers]].

## The loop

1. **Ground-read before dispatch.** Query review state, mergeable, HEAD, checks, and `reviewDecision` + per-PR reviews (`gh api .../pulls/<n>/reviews`). Know the review state before re-treading it.

2. **Fan independent reviewers via `swarm_dispatch`**, read-only on the main tree, scoped to the diff's lanes. Collect with `swarm_collect`. One independent reviewer minimum; reading my own diff is not a review.

3. **Converge.** Address every `issue:` finding. For `suggestion:` and `nitpick:` findings: make a judgement call on whether to implement — do not re-battle over a suggestion. Either way, always leave a threaded reply on the finding stating the decision (implemented at `<sha>`, or declined with short reason). After a round or two with findings addressed and CI green, further battles that surface nothing new are churn. Re-battle only on substantive scope change or if Josh asks, and scope the re-battle to the new change only.

4. **Resolve verdict from inline threads, against the AC.** Read live inline comments first (`gh api .../pulls/<n>/comments`). Agent reports are supplementary; threads are where findings live. Check the PR meets its issue's AC, not just that commits are clean. I resolve the verdict; do not ask permission to fire the bot.

5. **Fire bot review.** `gh workflow run bot-review.yml -f pr=N -f event=APPROVE|REQUEST_CHANGES|COMMENT -f body="..."`. Body highlights individual review comments, attributed, under 400 chars, verdict on its own line. No aggregated synthesis.

6. **Push and move on.** CI runs itself. Act only on failure. In-progress CI is theirs to carry. Josh merges if he agrees; the bot APPROVE is not the merge click.

## Design/doc PRs

Battle the idea with devils-advocate as required lane. The battle is generative (the design may change), not a confidence pass. Re-battle after substantive rewrite, not typo fixes.
