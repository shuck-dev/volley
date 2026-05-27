# AI

How the agent system that helps build Volley! is shaped, and what it's allowed to do. The runtime reference (role rosters, commit templates, tier table) lives in [`ai/swarm/README.md`](../../ai/swarm/README.md); the protocol material lives in [`ai/skills/gru/dispatch.md`](../../ai/skills/gru/dispatch.md), [`ai/skills/minions/commits.md`](../../ai/skills/minions/commits.md), and [`ai/skills/minions/reviewers.md`](../../ai/skills/minions/reviewers.md). What's in flight reads off Linear's `Dispatched` state and `gh pr list`, not a tracked board. This folder is the design layer above all of those.

| Doc | Purpose |
|---|---|
| [Swarm Architecture](swarm-architecture.md) | The ten-stage mission lifecycle (interrogate through cleanup), then the rationale: the Gru-and-minions model, two pools, scratchpad layout, worktree discipline, session tiers, PR verdict flow, and the open spikes still in motion. |
| [Dispatcher Focus and WIP](dispatcher-focus-and-wip.md) | Why the dispatcher caps its own open coordination threads and parallelises through fan-out: the throughput math, the switching tax, and the orchestrator-worker evidence. |

## Agent-assisted writing

The open-development essay stays human-facing under [`research/`](../research/the-case-for-open-development.md); its style guide, audits, and critiques are agent-facing and live here.

| Doc | Purpose |
|---|---|
| [STYLE](STYLE.md) | The guide every editor, human or agent, reads before touching the essay: voice, forbidden tics, citation rules, AI prose tells. |
| [Why AI Loves Em-Dashes](why-ai-loves-em-dashes.md) | Research note on the em-dash prose tell. |
| `meta/` | Essay planning and audits: `BOOK-EXTENSION`, `PERSUASION-AUDIT`, and `archive/` of completed fact-check, citation, and misattribution audits. |
| `critiques/` | Critical reviews of the essay across rounds. |
