---
name: dandori
description: Mission-planning interrogation for Gru. Walk the eight steps in order before filing a project, milestone, or dispatching minions.
---

# Mission dandori

The interrogation order Gru runs when planning a new mission. Walk the steps; do not skip ahead to filing or dispatch.

**Trigger.** Josh says "dandori" on new work, or Gru spots a new-mission proposal trigger (a request that's bigger than one ticket and needs a verification beat).

**Pairs with:** `designs/process/dandori.md` (human-readable canon) and `designs/process/missions-and-projects.md` (taxonomy).

## The eight steps

1. **Mission or ticket?** Big enough for a milestone with a verification beat (Ride or CI gate), or just an Urgent ticket? If one ticket and the AC is the verification, file as Urgent and stop.

2. **Project.** Apply the linear-scope rule: a project's scope is what completes inside it. If the work spans multiple existing projects, the boundary is wrong; move tickets, merge projects, or file a new one.

3. **Goals.** Terse numbered list, one line per goal, no prose.

4. **Scope-expansion guard.** For any goal that could sprawl (CI gate, audit, doc rewrite, contract change), name the cap. Broader work files as follow-up tickets after the mission, never inside it.

5. **Ride.** Player playtest or CI run? Ride ticket files in the same project with the milestone set. AC names the player-observable flows the rework must not regress, or the CI signal that proves the gate. Code-inspection findings file as Battle or code-review tickets, not Ride ACs.

6. **Mission codename.** Gru-canon: two-word handle from the Despicable Me / Minions lexicon. Opaque; the codename does not leak the mission's content. The milestone description does.

7. **Crew.** Per work unit:
   - Impl writer.
   - Test author, paired with impl when a hook forces failing tests + impl into one commit. Often folds into impl when the work itself is test code.
   - Reviewers: code-quality, gdscript-conventions, test-coverage by default, plus domain reviewers the diff fires (signals-lifecycle, godot-scene, save-format-warden, asset-pipeline, ci-and-workflows, supply-chain-scout, docs-and-writing).
   - Battlers: devils-advocate to challenge the approach; integration-scenario-author to write adversarial scenarios.

   Each minion gets a codename from the rotating pool (Galaxy Friends, Hitchhiker's, Oddworld, Omori, Outer Wilds Hearthians and Nomai, Martha) chosen to fit the case. Codename rotates per work unit; role is stable.

8. **Confirm.** List the project, milestone, goals, ride, codename, and full crew. Wait for go before dispatching.

## What this skill replaces

Memory rule `feedback_dandori_structure.md` mirrors this skill; both must agree. Update both when the rule changes.
