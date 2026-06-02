# Swarm Architecture

How Volley's parallel agent system is shaped, why it is shaped that way, and where the open edges still are. Reference material (role rosters, commit templates, tier table) lives in [`ai/swarm/README.md`](../../ai/swarm/README.md); the protocol material lives in [`.claude/skills/dispatch/SKILL.md`](../../.claude/skills/dispatch/SKILL.md), [`.claude/skills/commits/SKILL.md`](../../.claude/skills/commits/SKILL.md), and [`.claude/skills/reviewers/SKILL.md`](../../.claude/skills/reviewers/SKILL.md). What's in flight reads off Linear's `Dispatched` state and `gh pr list`, not a tracked board. This doc is the design layer above all of them: it opens with the lifecycle, the five stages a mission runs in order, then the rationale for why the system is shaped this way.

## The lifecycle

Not all work earns the lifecycle. A single ticket whose acceptance criteria are their own verification files and skips straight to Build. What runs the full arc is a mission: work with several units, or a verification beat (a Ride or a CI gate) at the end.

A mission runs five stages, from a ticket landing on the desk to the work merging. Each stage states what happens and names the doc that owns the detail. Stages 1 to 3 are the planning arc; 4 to 5 are execution.

1. **Scope.** Read the issue's full AC, open every linked design doc, grep any term in the AC that is not already concrete, check memory. Surface each ambiguity as one precise question and wait for the answer; only zero ambiguities proceeds. A proposal is never the first response to an issue being named. Give the mission a short label if one helps the dispatch briefs; that is a convenience, not a step.

2. **File.** Before any work begins, the milestone exists on the correct project with a one-sentence description and its goals as a terse numbered list (one line each), the Ride exists if the mission needs one, and every constituent issue is attached. Issues are scoped from what is already in the cycle, never moved in to suit the mission. Project taxonomy is in [`missions-and-projects.md`](../process/missions-and-projects.md); the shapes work takes (bug, spike, feature) are in [`flow-shapes.md`](../process/flow-shapes.md).

3. **Plan.** Per work unit: name the crew, recon the surfaces, name the scope cap, decide the split shape, confirm. Recon dispatches a read-only minion to map each unit's fix surface and the file overlap across units, so concurrent worktrees get non-overlapping write slices, or file-sharing units collapse into one serialized stream. Detail in [`dandori.md`](../../.claude/skills/dandori/SKILL.md).

4. **Build.** The seven-step minion flow runs per work unit: claim the ticket, place it in the cycle, log progress, sync before opening, open the challenge, hand off, block or spin. Worktree isolation, tier discipline, and the paired-dispatch shapes live in [`dispatch.md`](../../.claude/skills/dispatch/SKILL.md). Review, merge, and teardown are steps inside Build, not separate stages:
   - **Review is a dispatcher spot-check by default.** Read the diff, run the suite, verify the behaviour holds. No reviewer fan-out. A full reviewer battle fires only when Josh asks for one; it is not auto-triggered by the diff. When asked, fan only the scope-matched reviewers, run one round, and re-check a blocked finding with the one reviewer who raised it, not a fresh fan-out. A big PR is one review surface, reviewed once at the right depth, never re-battled per commit. The verdict contract (for when a battle does run) is in [`reviewers.md`](../../.claude/skills/reviewers/SKILL.md).
   - **Merge** rides the queue: it pulls the challenge into a merge group, re-runs lint and tests against `main` plus the change, then fast-forwards. Each challenge stands alone against current `main`. Josh merges; the dispatcher does not.
   - **Teardown** on done: worktrees come down, merged branches delete, per-task scratchpads scrub once keepers promote to memory or docs.

5. **Verify.** Only when the mission has something to play or gate. The player plays, or the CI gate runs, against the landed bundle. Findings file as new issues (a regression reopens its source issue), not as fixes folded into the Ride. A process retro (blockers, improvements, action items, per [`debrief.md`](../../.claude/skills/debrief/SKILL.md)) runs on request, not by default.

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
- Live state: not a tracked file. Linear's `Dispatched` status names the active minions; `gh pr list --json files,headRefName,number --state open` names the open challenges and the files each one touches. Cross-referencing those two queries is the modern equivalent of an Active table, without the merge-conflict tax.

Point-to-point minion messaging is not in the design. Handoffs go through Gru, who acts as the switchboard. An earlier `inbox/{name}.md` mailbox surface was reserved for directed handoffs but stayed empty across several swarms, so it was dropped. If a concrete minion-to-minion use case shows up it can return cleanly; for now Gru is sufficient.

The split between tracked and gitignored mattered when there was a tracked live board. `ai/PARALLEL.md` was that board until SH-328: every concurrent claim wrote a row, every merge wrote an Activity Log line, and every challenge picked up the same file as a conflict. Linear and `gh pr list` already carry that state authoritatively, so the tracked board retired and the per-claim conflict tax went with it. Rich per-minion state still lives in gitignored per-task scratchpads.

## Worktree discipline

Code-writing minions dispatch with `isolation: "worktree"` so each gets a clean tree at `../volley-sh-N` and cannot collide with siblings. Non-worktree minions (research, design-doc-reader, devils-advocate, the read-only reviewers) stay on the main tree. Gru owns every merge back; minions never merge into main and never merge each other's worktrees. When a ticket closes Gru removes the worktree and deletes the branch.

## Commit discipline

Minions commit like a proper team. Each code-writing minion stages and commits its own work from its worktree with a DCO sign-off and a role tag in the commit body. The commit author is Josh per DCO, so the role identity lives in the body, not the author field. Gru merges worktrees back without squashing, preserving per-minion attribution in the history. The reader can scan the commit list and see which minion produced which change.

Review happens in the Dandori Challenge, never on local files. A reviewer's verdict only reflects reality when its findings are posted to the actual review surface.

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

Reviewers apply no verdict label. They post inline findings and report their verdict (approve / block) to the organiser, which synthesises consensus and posts one bot synthesis review on every review round under `shuck-volley-bot[bot]` via `.github/workflows/bot-review.yml`: APPROVE on a clean pass, REQUEST_CHANGES if any reviewer blocked. Every inline comment opens with `**<codename>**` so the attribution lives in the text. The reviewer contract (verdict shape, brevity caps, inline-comment posting, re-review protocol) lives in [`.claude/skills/reviewers/SKILL.md`](../../.claude/skills/reviewers/SKILL.md).

Two properties move off mechanism onto organiser discipline: the strictest-verdict rule (a block outweighs an approve) is the organiser's synthesis, not a reconciler workflow, and the verdict surface resolves only while an organiser session is live, since no event-driven path posts or clears it otherwise. Accepted for a solo-maintainer cadence; inline findings land regardless. If the bot App is down, no synthesis verdict posts, but inline findings and the maintainer's manual merge are unaffected.

Dispatch happens at declared review moments (Dandori Challenge first opens, author signals ready for re-review), not every push. Gru partitions the `<last-approved>..<head>` diff by reviewer scope and only dispatches reviewers whose scope was touched. Scope-filter empty means immediate approve.

Minions never merge. The required checks are `Tests` and `Lint`; the maintainer's manual merge is the approval, and the bot synthesis review is attribution, not a required check. A stale bot approval is dismissed on push by the ruleset's dismiss-stale-reviews-on-push, while a bot request-changes persists until the next review.

## Live state versus stable protocol

The board bloats if protocol lives with state. The earlier `ai/PARALLEL.md` mixed both, which was the immediate cause of its merge-conflict tax. Today the live state lives in Linear's `Dispatched` status and `gh pr list`; the stable how-to (seven-step flow, ground rules, tier system, paired dispatch, reviewer contract) lives in the skill docs under `.claude/skills/`; the role rosters and commit templates live in `ai/swarm/README.md`; the design rationale (this doc) lives under `designs/`.

This is one of the patterns the multi-agent literature converges on. LangGraph and AutoGen centralise state in one object, which reports as a write-contention bottleneck under parallel load. Claude Code's own Agent Teams design landed on a shared task list plus per-agent mailboxes rather than one fat board, and that is structurally what Volley is moving toward. The pain shows up as merge conflicts on the shared surface when two minions claim at the same time; the fix is to keep the shared surface small and push rich state into per-owner files that do not conflict.

## Freshness and cleanup

Freshness is a query, not a header line. `mcp__linear__list_issues(state: "Dispatched", cycle: "active")` reads the live set; if the result is empty when minions are mid-flight, the cycle hasn't been promoted, not the board. The Tuesday sweep that used to rewrite a header still happens; it just no longer leaves a tracked artefact.

The sweep rules:

- A challenge merge moves its Linear ticket to Done. No table row to migrate.
- Cycle close clears `Dispatched` issues that did not finish. Carry-over rolls into the next cycle.
- Blocks live as Linear comments on the ticket, escalated when needed; no Blocked table to clear.
- The narrative history is the git log plus Linear comments; nothing gets truncated.

Gru runs the cycle-cut the same turn it lists candidates for the new cycle.

## No Claude from PR-triggered workflows

A workflow triggered by `pull_request` or `pull_request_target` (or any related event) never dispatches Claude. Outside contributors' PRs can carry prompt-injection payloads in commit messages, PR bodies, code, or comments, and a CI job running Claude against those surfaces would hold the OAuth token and repo write permission while reading hostile content. Gru dispatches reviewers manually from the local machine, where the blast radius is a single minion in a sandbox.

Standing PR-triggered workflows may only do mechanical GitHub API work: strip and apply labels, validate shape, route. They do not spawn an LLM. `schedule`, `workflow_dispatch`, and `push` on internal branches are reachable only by maintainers and may dispatch Claude freely.

## Reconciliation, not collision detection

When two spikes work adjacent territory they can silently disagree on naming. The earlier fix (a Vocabulary claims column on the live board) tried to format a judgment call into a table cell, which does not work: there is no standard lexicon to check against, so collision detection is a reasoning task, not a lookup.

The plan: a reconciliation minion reads all live per-task files plus the relevant tickets and reasons about whether two claims describe the same concept under different names. It runs at claim time (preventive) and pre-push (detective), reports candidate collisions to Gru, and Gru escalates to Josh. Task files carry claims as plain prose, not schema.

Tracked as [SH-191](https://linear.app/shuck-games/issue/SH-191/spike-reconciliation-agent-for-naming-drift). Dependent spikes: [SH-192](https://linear.app/shuck-games/issue/SH-192/spike-per-task-file-schema) (per-task file schema, which the reconciler reads) and [SH-193](https://linear.app/shuck-games/issue/SH-193/spike-activity-log-archival-policy) (activity log archival).

## References

- [MAST: Why Do Multi-Agent LLM Systems Fail?](https://arxiv.org/abs/2503.13657) (retrieved 2026-04-22)
- [Anthropic: How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) (retrieved 2026-04-22)
- [Claude Code Agent Teams overview (MindStudio)](https://www.mindstudio.ai/blog/claude-code-agent-teams-shared-task-list) (retrieved 2026-04-22)
- [LLM-Based Multi-Agent Blackboard System](https://arxiv.org/abs/2510.01285) (retrieved 2026-04-22)
- [Exploring Advanced LLM MAS Based on Blackboard](https://arxiv.org/abs/2507.01701) (retrieved 2026-04-22)
- Research scratchpad: `ai/scratchpads/research-multi-agent-coordination-2026-04-22.md`
