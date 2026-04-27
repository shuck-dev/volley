# Mission dandori

The interrogation order for planning a new mission. Walk the steps in order; don't skip to filing or dispatch.

Pairs with `missions-and-projects.md` (the taxonomy) and the swarm conventions in `ai/`.

## 1. Mission or ticket?

Is this big enough to be a mission, or is it a single Urgent ticket?

A mission needs a verification beat: a Ride (player playtest) or a clear non-player gate (e.g. CI run). If the work is one ticket and the AC is the verification, file it as Urgent and stop.

## 2. Project

Which project does the mission live in? Apply the linear-scope rule from `missions-and-projects.md`: a project's scope is what completes inside it. If the mission needs work in multiple existing projects, the boundaries are wrong; resolve by moving tickets, merging projects, or filing a new one.

## 3. Goals

Terse numbered list. One line per goal. No prose.

## 4. Scope-expansion guard

For any goal that could naturally sprawl (CI gate, audit, doc rewrite, contract change), name the cap. Broader work files as follow-up tickets after the mission, not inside it.

## 5. Ride

Player playtest or CI run? Ride ticket files in the same project with the milestone set. AC names the player-observable flows the rework must not regress, or the CI signal that proves the gate.

Code-inspection findings file as separate Battle or code-review tickets, not Ride ACs.

## 6. Mission codename

Gru-canon: two-word handle from the Despicable Me / Minions lexicon. Opaque: the codename doesn't leak the mission's content. The milestone description does.

## 7. Minion crew

Full team per work unit:

- **Impl** (writer of the change). Often folds in test authoring when the work is test code itself.
- **Test author**, paired with impl when a hook or gate forces failing tests + impl into one commit.
- **Reviewers**: code-quality, gdscript-conventions, test-coverage by default, plus the domain reviewers the diff fires (signals-lifecycle, godot-scene, save-format-warden, asset-pipeline, ci-and-workflows, supply-chain-scout, docs-and-writing).
- **Battlers**: devils-advocate to challenge the approach, integration-scenario-author to write adversarial scenarios that try to expose gaps.

Each minion gets a codename from the pool (Galaxy Friends, Hitchhiker's, Oddworld, Omori, Outer Wilds Hearthians and Nomai, Martha) chosen to fit the case. Codename rotates per work unit; role is stable.

## 8. Confirm before dispatch

List the crew and wait for go. Don't dispatch until the codename and crew are confirmed.

## Worked example

Vector Squared (Test Rework, 2026-04-27):

1. Mission, not ticket: scope spans timeout tests, integration contract, behavioural audit, CI gate.
2. New project Test Rework. Tickets moved out of Minion Hardening (wrong scope: that project is for swarm/agent hardening).
3. Goals: suite under 2s; real input on every player AC; behavioural review; patterns documented; CI gate.
4. CI gate capped to one workflow step, one number. New gate types file as follow-ups.
5. Ride: regression playtest. No new player surface to verify, but the rework could regress existing flows.
6. Codename: Vector Squared.
7. Crew: Feldspar (impl SH-254), Hornfels (impl SH-253), reviewers Marvin / Slartibartfast / Sunny / Mabel / Solanum / Aubrey / Riebeck, battlers Ford / Stranger / Abe / Kel.
8. Confirm, then dispatch.
