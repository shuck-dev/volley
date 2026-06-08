---
name: battle
description: Dispatcher-side entry to battling a challenge: the review loop, owned by the memory branch feedback_battle_review_process. Read when battling any PR. The challenge body shape is the `pr` skill; the per-reviewer contract is the `reviewers` skill.
---

# Battling a challenge

A *challenge* is the PR (see [`pr`](../pr/SKILL.md)); a *battle* is the review run against it. The loop is owned by the memory branch [[feedback_battle_review_process]] under [[trunk_dev_cycle]]: descend there for the full process, and into its leaves for depth. The reviewer agent's own contract lives in [`reviewers`](../reviewers/SKILL.md).

The shape, in brief:

- A battle is a confidence pass over a shipped challenge, dispatched to minions, not an in-thread audit.
- The floor is one independent reviewer on every PR. Reading my own diff is not a review; "yours to merge" off my own reading alone is the tell.
- The loop: ground-read review state, dispatch reviewers scoped to the diff, converge without churn, resolve the verdict against the issue's AC from the inline threads, fire the bot review, then push and move on (CI calls back only on failure). Josh's merge is the gate.

Read the memory branch for the full process.
