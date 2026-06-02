---
name: dandori
description: Gru's implementation-plan walk, run after the mission milestone is filed and before any minion dispatches. Per work unit, name the crew, recon the surfaces, name the scope cap, decide the split shape, confirm. Not the mission-shape walk; that is stages 1 to 2 (Scope, File) of the lifecycle.
---

# Dandori, the impl plan

Dandori is the implementation plan (stage 3, Plan), not the mission-shape walk. By the time it runs, the mission is already scoped and filed (milestone on the correct project, Ride if needed, issues attached). Dandori narrows to: for each work unit, who works it, what it touches, how it is capped, and a confirm before go.

**Trigger.** Josh says "dandori" on a filed mission, or Gru reaches the planning of a mission whose milestone already exists. If the milestone is not filed yet, that is earlier in the lifecycle: do stages 1 to 2 (Scope, File) first.

**Pairs with:** [`designs/ai/swarm-architecture.md`](../../../designs/ai/swarm-architecture.md) (the full five-stage lifecycle; dandori is stage 3, Plan), [`designs/process/dandori.md`](../../../designs/process/dandori.md) (human-readable), and [`dispatch.md`](../dispatch/SKILL.md) (the seven-step flow that runs after confirm).

## The five steps

1. **Crew.** Per work unit:
   - Impl writer. Often folds in test authoring when the work itself is test code.
   - Test author, paired with impl when a hook forces failing tests + impl into one commit.
   - Reviewers: code-quality, gdscript-conventions, test-coverage by default, plus the domain reviewers the diff fires (signals-lifecycle, godot-scene, save-format-warden, asset-pipeline, ci-and-workflows, docs-and-writing).
   - Battlers: devils-advocate to stress-test the approach; integration-scenario-author for adversarial cross-system scenarios.

   Each minion gets a codename from the rotating pool (Gravity Falls, Hitchhiker's, Oddworld, Omori, Outer Wilds Hearthians and Nomai, Martha) chosen to fit the case. Codename rotates per work unit; role is stable.

2. **Recon the surfaces.** Before confirm, dispatch a read-only Explore minion to locate each work unit's fix surface (file plus function) and produce a file-overlap map across the units. Use it to lock non-overlapping write slices for concurrent worktrees, or to collapse units that share a file into one serialized stream. This grounds the crew's slices in current state instead of inferring them from the issue bodies. Catching two units that share a file at plan time beats catching it after they clobber each other on the same branch. Recon is read-only and reads excerpts, not the impl; the claiming minion still does its own step-1 file work.

3. **Scope-expansion guard.** For any goal that could sprawl (CI gate, audit, doc rewrite, contract change), name the cap. Broader work files as follow-up issues after the mission, never inside it.

4. **Split shape.** Decide how many PRs the feature becomes, governed by [`feedback_feature_pr_decomposition`]: the fewest PRs such that each one is independently shippable on trunk (compiles, suite green, no half-wired feature). Default is one feature, one branch, one PR (units fold serially onto it). When units can be made genuinely independent by landing a shared contract first, a parallel split into independent PRs is preferred, but only up to **3 PRs**; past 3 the contract churn dominates, so go serial. The **+1000 added-line** cap is a hard ceiling per PR: when the accumulated diff crosses it, PR the largest independently-shippable prefix and move the remainder to a follow-up off main (a forced 1->2 split is fine). Never cut a unit in half for the line count. A feature that genuinely cannot be sliced into independently-shippable sub-1000-line PRs is a planning smell to flag here, not at fold time.

5. **Confirm.** List the crew, the recon-grounded slices, the scope caps, and the split shape. Wait for go before dispatching.

## What this skill replaces

Memory rules `feedback_mission_lifecycle.md` (Phase 4) and `feedback_dandori_structure.md` mirror this skill; all three must agree. Update them together when the rule changes. The earlier mission-shape steps (interrogate, codename, file) moved up to the lifecycle doc; dandori is the impl plan only.
