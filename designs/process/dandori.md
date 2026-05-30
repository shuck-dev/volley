# Dandori, the impl plan

Dandori is stage 4 of the swarm lifecycle: the implementation plan, run after the mission is filed and before any minion dispatches. Interrogating the work, picking a codename, and filing the milestone happen earlier, as stages 1 to 3, owned by [`swarm-architecture.md`](../ai/swarm-architecture.md). By the time dandori runs, the milestone exists on the right project, the Ride exists if the mission needs one, and the issues are attached.

Dandori narrows to four questions, per work unit: who works it, what it touches, how it is capped, and a confirm before go.

Pairs with [`missions-and-projects.md`](missions-and-projects.md) (the nouns), [`flow-shapes.md`](flow-shapes.md) (the shapes work takes inside a mission), and the operational checklist in [`.claude/skills/dandori/SKILL.md`](../../.claude/skills/dandori/SKILL.md).

## 1. Crew

Full team per work unit:

- **Impl** (writer of the change). Often folds in test authoring when the work is test code itself.
- **Test author**, paired with impl when a hook or gate forces failing tests + impl into one commit.
- **Reviewers**: code-quality, gdscript-conventions, test-coverage by default, plus the domain reviewers the diff fires (signals-lifecycle, godot-scene, save-format-warden, asset-pipeline, ci-and-workflows, docs-and-writing).
- **Battlers**: devils-advocate to challenge the approach, integration-scenario-author to write adversarial scenarios that try to expose gaps.

Each minion gets a codename from the pool (Gravity Falls, Hitchhiker's, Oddworld, Omori, Outer Wilds Hearthians and Nomai, Martha) chosen to fit the case. Codename rotates per work unit; role is stable.

## 2. Recon the surfaces

Before confirm, a read-only minion maps each work unit's fix surface and the file overlap across units. The crew's write slices come from that map, not from inference off the issue bodies: units with disjoint files fan as concurrent worktrees, units that share a file collapse into one serialized stream. The recon runs before dispatch so a shared file is caught while it is still a planning note, not after two minions have clobbered each other on the same branch.

## 3. Scope-expansion guard

For any goal that could naturally sprawl (CI gate, audit, doc rewrite, contract change), name the cap. Broader work files as follow-up tickets after the mission, not inside it.

## 4. Confirm before dispatch

List the crew, the recon-grounded slices, and the scope caps. Wait for go. Don't dispatch until they are confirmed.

## Worked example

A bug-pass mission, milestone already filed with four bugs attached and a high-level Ride:

1. Crew: one impl per work unit, default reviewers on each, devils-advocate on the unit with the subtle gating logic.
2. Recon: a read-only minion reports that three of the four bugs all modify the same manager script and only the fourth is isolated. The plan collapses the three into one serialized stream and fans the fourth as a parallel worktree.
3. Scope guard: each fix stays to its repro; anything broader the recon surfaces files as a follow-up, not folded in.
4. Confirm the streams and slices, then dispatch.
