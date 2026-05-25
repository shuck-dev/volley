---
name: dandori
description: Gru's implementation-plan walk, run after the mission milestone is filed and before any minion dispatches. Per work unit, name the crew, recon the surfaces, name the scope cap, confirm. Not the mission-shape walk; that is stages 1 to 3 of the lifecycle.
---

# Dandori, the impl plan

Dandori is the implementation plan, not the mission-shape walk. By the time it runs, the mission is already interrogated, codenamed, and filed (milestone on the correct project, Ride if needed, issues attached). Dandori narrows to: for each work unit, who works it, what it touches, how it is capped, and a confirm before go.

**Trigger.** Josh says "dandori" on a filed mission, or Gru reaches the planning of a mission whose milestone already exists. If the milestone is not filed yet, that is earlier in the lifecycle: do stages 1 to 3 first.

**Pairs with:** [`designs/ai/swarm-architecture.md`](../../../designs/ai/swarm-architecture.md) (the full ten-stage lifecycle; dandori is stage 4), [`designs/process/dandori.md`](../../../designs/process/dandori.md) (human-readable), and [`dispatch.md`](dispatch.md) (the seven-step flow that runs after confirm).

## The four steps

1. **Crew.** Per work unit:
   - Impl writer. Often folds in test authoring when the work itself is test code.
   - Test author, paired with impl when a hook forces failing tests + impl into one commit.
   - Reviewers: code-quality, gdscript-conventions, test-coverage by default, plus the domain reviewers the diff fires (signals-lifecycle, godot-scene, save-format-warden, asset-pipeline, ci-and-workflows, docs-and-writing).
   - Battlers: devils-advocate to stress-test the approach; integration-scenario-author for adversarial cross-system scenarios.

   Each minion gets a codename from the rotating pool (Galaxy Friends, Hitchhiker's, Oddworld, Omori, Outer Wilds Hearthians and Nomai, Martha) chosen to fit the case. Codename rotates per work unit; role is stable.

2. **Recon the surfaces.** Before confirm, dispatch a read-only Explore minion to locate each work unit's fix surface (file plus function) and produce a file-overlap map across the units. Use it to lock non-overlapping write slices for concurrent worktrees, or to collapse units that share a file into one serialized stream. This grounds the crew's slices in current state instead of inferring them from the issue bodies, which is what catches two units silently clobbering each other on a shared file before they dispatch rather than after. Recon is read-only and reads excerpts, not the impl; the claiming minion still does its own step-1 file work.

3. **Scope-expansion guard.** For any goal that could sprawl (CI gate, audit, doc rewrite, contract change), name the cap. Broader work files as follow-up issues after the mission, never inside it.

4. **Confirm.** List the crew, the recon-grounded slices, and the scope caps. Wait for go before dispatching.

## What this skill replaces

Memory rules `feedback_mission_lifecycle.md` (Phase 4) and `feedback_dandori_structure.md` mirror this skill; all three must agree. Update them together when the rule changes. The earlier mission-shape steps (interrogate, codename, file) moved up to the lifecycle doc; dandori is the impl plan only.
