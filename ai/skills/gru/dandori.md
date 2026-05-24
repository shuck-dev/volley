---
name: dandori
description: The mission's implementation plan. Walk after the milestone, Ride, and attached issues are filed; before any minion dispatches.
---

# Mission dandori

The implementation plan, run after the mission is filed and before minions dispatch. Crew per work unit, scope guard, confirm.

**Trigger.** Josh says "dandori" on a filed mission, or Gru reaches the post-filing gate on a multi-issue milestone.

**Pairs with:** `designs/process/dandori.md` (high-level canon), `designs/process/missions-and-projects.md` (mission filing taxonomy), `ai/swarm/README.md` (dispatch flow that follows), memory `feedback_mission_lifecycle.md` (rule body, all four phases).

## What dandori is not

- Pre-mission interrogation (reading ACs, listing ambiguities) is its own discipline, before filing.
- Filing the mission (project, codename, milestone, Ride, attached issues) is its own step, before dandori.

Dandori is the impl plan, not the full mission walk.

## The three steps

1. **Crew per work unit.** For each issue attached to the milestone, name:
   - Impl writer (often folds in test authoring when the work is test code).
   - Test author, paired with impl when a hook forces failing tests + impl into one commit.
   - Reviewers: code-quality, gdscript-conventions, test-coverage by default; plus domain reviewers the diff fires (signals-lifecycle, godot-scene, save-format-warden, asset-pipeline, ci-and-workflows, docs-and-writing).
   - Battlers: devils-advocate to stress-test the approach; integration-scenario-author for adversarial cross-system scenarios.

   Each minion gets a codename from the rotating pool (Gravity Falls, Hitchhiker's, Oddworld, Omori, Outer Wilds Hearthians and Nomai, Martha) chosen to fit the case. Codename rotates per work unit; role is stable.

2. **Scope-expansion guard.** For any goal that could sprawl (CI gate, audit, doc rewrite, contract change), name the cap. Broader work files as follow-up issues after the mission, never inside it.

3. **Confirm.** List the crew and scope. Wait for go before dispatching.
