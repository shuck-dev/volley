# Mission dandori

The implementation plan. Runs **after** the mission is filed (milestone, Ride, attached issues) and **before** minions dispatch. Crew per work unit, scope guard, confirm.

Pairs with [`missions-and-projects.md`](missions-and-projects.md) (the nouns, including how missions get filed) and [`flow-shapes.md`](flow-shapes.md) (the bug / spike / feature shape of work inside a mission).

Pre-mission interrogation (reading ACs, listing ambiguities) and filing (project, codename, milestone, Ride, attached issues) come before dandori. See `missions-and-projects.md` for filing and `ai/swarm/README.md` for the swarm flow that follows.

## 1. Crew per work unit

For each issue attached to the milestone, name the team:

- **Impl** (writer of the change). Often folds in test authoring when the work is test code itself.
- **Test author**, paired with impl when a hook or gate forces failing tests + impl into one commit.
- **Reviewers**: code-quality, gdscript-conventions, test-coverage by default; plus the domain reviewers the diff fires (signals-lifecycle, godot-scene, save-format-warden, asset-pipeline, ci-and-workflows, docs-and-writing).
- **Battlers**: devils-advocate to challenge the approach; integration-scenario-author to write adversarial cross-system scenarios.

Each minion gets a codename from the pool (Gravity Falls, Hitchhiker's, Oddworld, Omori, Outer Wilds Hearthians and Nomai, Martha) chosen to fit the case. Codename rotates per work unit; role is stable.

## 2. Scope-expansion guard

For any goal that could naturally sprawl (CI gate, audit, doc rewrite, contract change), name the cap. Broader work files as follow-up tickets after the mission, not inside it.

## 3. Confirm before dispatch

List the crew and the scope. Wait for go. Don't dispatch until the codenames and the scope are confirmed.

## Worked example

Vector Squared (Test Rework, 2026-04-27), crew + scope:

- Crew: Feldspar (impl SH-254), Hornfels (impl SH-253), reviewers Marvin / Slartibartfast / Sunny / Mabel / Solanum / Aubrey / Riebeck, battlers Ford / Stranger / Abe / Kel.
- Scope: CI gate capped to one workflow step, one number; new gate types file as follow-ups.
- Confirm, then dispatch.
