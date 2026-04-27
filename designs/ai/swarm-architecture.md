# Swarm Architecture

How Volley's parallel agent system is shaped, why it is shaped that way, and where the open edges still are. Reference material (role rosters, commit templates, tier table) lives in [`ai/swarm/README.md`](../../ai/swarm/README.md); the live coordination board lives in [`ai/PARALLEL.md`](../../ai/PARALLEL.md). This doc is the design layer above both.

## The Gru model

A single Claude thread runs as Gru. Gru reads tickets, dandoris the fan-out, dispatches minions in parallel, merges diffs, and talks to Josh. Minions do the specialised work: write code, write tests, review diffs, draft docs, plan refactors. Gru writes almost no code.

This shape is a deliberate bet against the blackboard pattern. Blackboard systems let every agent post to and read from one shared surface, which reports 13 to 57 percent gains over master-slave when agents have overlapping expertise and the controller cannot reliably pick who does what (see the 2025 blackboard-architecture papers). Volley's roles are specialised and legible: `test-author` writes tests, `docs-and-writing` reviews prose, `ci-and-workflows` knows GitHub Actions. Gru does know who fits each ticket, so a blackboard buys overhead without the routing win. The orchestrator model keeps the authority single and the state small.

Anthropic's own write-up of the Research system says the same thing in plainer terms: each minion needs an objective, an output format, tool scope, and clear task boundaries. Gru's job is to supply those four cleanly and let the minion run. Most coordination pain in multi-agent systems traces back to fuzziness in one of the four; the MAST taxonomy attributes roughly 79 percent of production failures across seven frameworks to specification ambiguity. Sharper briefs beat fatter boards.

## Two pools

The impl pool produces artefacts: tickets, code, tests, plans, research, analysis. The reviewer pool applies verdicts: reads diffs, posts reasoning, labels PRs. Role names are permanent so routing stays stable over time. Codenames rotate per work unit, picked to fit each case's personality, so a tense save-integrity bug feels different from a warm narrative copy pass even when the same roles are in play. The full role table and codename pool live in the README.

## Scratchpad layout

Everything lives under `ai/swarm/`. Three kinds of file, one tracked surface, and one tracked board.

- `agents/{name}.md`: per-minion working state, gitignored, private to the worktree that owns it. Appends only.
- `tasks/{id}.md`: per-task work, one file per ticket, gitignored today. Carries claims, blocked-by, rich context for the minion working the ticket. Scrubs on ticket close.
- `README.md`: the tracked reference for how the swarm works. Stable; changes rarely.
- `ai/PARALLEL.md`: the tracked live board. Cycle header, Active, Done recent, Blocked, Activity log. Volatile; rewritten constantly.

Point-to-point minion messaging is not in the design. Handoffs go through Gru, who acts as the switchboard. An earlier `inbox/{name}.md` mailbox surface was reserved for directed handoffs but stayed empty across several swarms, so it was dropped. If a concrete minion-to-minion use case shows up it can return cleanly; for now Gru is sufficient.

The split between tracked and gitignored matters. PARALLEL.md is the one surface where siblings can see each other's claims, which means every concurrent-claim write is a merge conflict in waiting. That pressure keeps the board small and pushes rich structured state into per-task files instead.

## Worktree discipline

Code-writing minions dispatch with `isolation: "worktree"` so each gets a clean tree at `../volley-sh-N` and cannot collide with siblings. Non-worktree minions (research, design-doc-reader, devils-advocate, the read-only reviewers) stay on the main tree. Gru owns every merge back; minions never merge into main and never merge each other's worktrees. When a ticket closes Gru removes the worktree and deletes the branch.

## Commit discipline

Minions commit like a proper team. Each code-writing minion stages and commits its own work from its worktree with a DCO sign-off and a role tag in the commit body. The commit author is Josh per DCO, so the role identity lives in the body, not the author field. Gru merges worktrees back without squashing, preserving per-minion attribution in the history. The reader can scan the commit list and see which minion produced which change.

Review happens in the Dandori Challenge, never on local files. The `zaphod-approved` and `zaphod-blocked` labels only reflect reality when they are earned through the actual review surface.

## Session tiers

The swarm inherits Godot's session-tier system. Every minion declares a tier ceiling in its definition and Gru respects it.

- Tier 0 (static, headless) runs grep, read, validate, signal_map, impact_check, run_gut.sh, and `.gd` edits that do not touch scenes. Fully parallel. Most minions live here.
- Tier 1 (scene edits) covers node_ops, build_scene, save_scene, placement, scene_map, spatial_audit. Requires a worktree; parallelism is across worktrees.
- Tier 2 (runtime) covers run(play), state_inspect, verify_motion, screenshot, input, ui_map, perf_snapshot. Exclusive: one minion at a time, no parallel Tier 2 sessions. No Josh sign-off required; the constraint is the single running editor.

Gru picks the dispatch tier from the task, not the minion's ceiling. A specialist invoked for a signal-chain test stays at Tier 0 even if its ceiling is Tier 1.

## Sync points

Only two. Gru does not call standups.

A diff exists. Gru dispatches `pr-describer` and the reviewer fan-out matching the changed paths.

A work unit closes. Gru scrubs the scratchpad and promotes keepers.

Everything between those two points is parallel. Minions do not wait for each other unless a task's frontmatter explicitly declares `blocked_by`.

## PR verdict flow

Four labels live on PRs. Two are minion-applied, two are Josh-only.

- `zaphod-approved`: a reviewer read the diff and found it clean. Each reviewer applies its own.
- `zaphod-blocked`: a reviewer found something that needs a fix. Blocked supersedes approved.
- `approved-human`: Josh's sign-off. Required for merge.
- `action-required-human`: Josh's "I looked at this and want changes". Mutually exclusive with `approved-human`.

Reviewers post their own comments and apply their own labels; Gru does not aggregate or post on their behalf. Every comment opens with `**<codename>**` so the attribution lives in the text, not in the label alone. The reviewer contract (verdict shape, brevity caps, inline-comment posting, re-review protocol) lives in [`ai/skills/minions/reviewers.md`](../../ai/skills/minions/reviewers.md).

Dispatch happens at declared review moments (Dandori Challenge first opens, author signals ready for re-review), not every push. Gru partitions the `<last-approved>..<head>` diff by reviewer scope and only dispatches reviewers whose scope was touched. Scope-filter empty means immediate approve.

Minions never apply either human label. The `zaphod-*` namespace strips on every new commit so a push re-earns the verdict. The `Human Approved` merge-queue check fails "Action required" while `action-required-human` is present and "Needs human review" when neither human label is set.

## Live state versus stable protocol

The board bloats if protocol lives with state. `ai/PARALLEL.md` carries only live state: the cycle header, Active, Done recent, Blocked, Activity log. The stable how-to (roles, tiers, PR comment templates, commit discipline) lives in `ai/swarm/README.md`. The design rationale (this doc) lives under `designs/`.

This is one of the patterns the multi-agent literature converges on. LangGraph and AutoGen centralise state in one object, which reports as a write-contention bottleneck under parallel load. Claude Code's own Agent Teams design landed on a shared task list plus per-agent mailboxes rather than one fat board, and that is structurally what Volley is moving toward. The pain shows up as merge conflicts on the shared surface when two minions claim at the same time; the fix is to keep the shared surface small and push rich state into per-owner files that do not conflict.

## Freshness and cleanup

The live board is scoped to the current cycle. `ai/PARALLEL.md` opens with `**Cycle:** <name> (<start> → <end>)` pulled from Linear's active cycle. That line is the freshness check: if it does not match the current cycle on read, the Tuesday sweep was skipped.

The sweep rules:

- Active to Done recent: the row moves when the Dandori Challenge merges and the Linear ticket closes.
- Done recent to removed: the rows rotate out at cycle close, as part of the Tuesday cycle-cut.
- Blocked: cleared manually when the blocker lifts.
- Activity log: truncated to the current cycle at cycle close.

Gru runs the sweep during cycle-cut, the same turn it lists candidates for the new cycle.

## No Claude from PR-triggered workflows

A workflow triggered by `pull_request` or `pull_request_target` (or any related event) never dispatches Claude. Outside contributors' PRs can carry prompt-injection payloads in commit messages, PR bodies, code, or comments, and a CI job running Claude against those surfaces would hold the OAuth token and repo write permission while reading hostile content. Gru dispatches reviewers manually from the local machine, where the blast radius is a single minion in a sandbox.

Standing PR-triggered workflows may only do mechanical GitHub API work: strip and apply labels, validate shape, route. They do not spawn an LLM. `schedule`, `workflow_dispatch`, and `push` on internal branches are reachable only by maintainers and may dispatch Claude freely.

## Reconciliation, not collision detection

When two spikes work adjacent territory they can silently disagree on naming. The earlier fix (a Vocabulary claims column on the live board) tried to format a judgment call into a table cell, which does not work: there is no canonical lexicon to check against, so collision detection is a reasoning task, not a lookup.

The plan: a reconciliation minion reads all live per-task files plus the relevant tickets and reasons about whether two claims describe the same concept under different names. It runs at claim time (preventive) and pre-push (detective), reports candidate collisions to Gru, and Gru escalates to Josh. Task files carry claims as plain prose, not schema.

Tracked as [SH-191](https://linear.app/shuck-games/issue/SH-191/spike-reconciliation-agent-for-naming-drift). Dependent spikes: [SH-192](https://linear.app/shuck-games/issue/SH-192/spike-per-task-file-schema) (per-task file schema, which the reconciler reads) and [SH-193](https://linear.app/shuck-games/issue/SH-193/spike-activity-log-archival-policy) (activity log archival).

## References

- [MAST: Why Do Multi-Agent LLM Systems Fail?](https://arxiv.org/abs/2503.13657) (retrieved 2026-04-22)
- [Anthropic: How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) (retrieved 2026-04-22)
- [Claude Code Agent Teams overview (MindStudio)](https://www.mindstudio.ai/blog/claude-code-agent-teams-shared-task-list) (retrieved 2026-04-22)
- [LLM-Based Multi-Agent Blackboard System](https://arxiv.org/abs/2510.01285) (retrieved 2026-04-22)
- [Exploring Advanced LLM MAS Based on Blackboard](https://arxiv.org/abs/2507.01701) (retrieved 2026-04-22)
- Research scratchpad: `ai/scratchpads/research-multi-agent-coordination-2026-04-22.md`
