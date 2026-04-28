# AI

How the agent system that helps build Volley! is shaped, and what it's allowed to do. The runtime reference (role rosters, commit templates, tier table) lives in [`ai/swarm/README.md`](../../ai/swarm/README.md); the protocol canon lives in [`ai/skills/gru/dispatch.md`](../../ai/skills/gru/dispatch.md), [`ai/skills/minions/commits.md`](../../ai/skills/minions/commits.md), and [`ai/skills/minions/reviewers.md`](../../ai/skills/minions/reviewers.md). What's in flight reads off Linear's `Dispatched` state and `gh pr list`, not a tracked board. This folder is the design layer above all of those.

| Doc | Purpose |
|---|---|
| [Swarm Architecture](swarm-architecture.md) | The Gru-and-minions model, two pools, scratchpad layout, worktree discipline, session tiers, PR verdict flow, and the open spikes still in motion. |

Related research, kept under [`research/`](../research/the-case-for-open-development.md): the open-development essay touches on what stays human in the work as AI takes over the boilerplate.
