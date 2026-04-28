# ai/

Coordination for AI agents working on this repo. Not design, not code: operational state.

## Files

- [skills/gru/dispatch.md](skills/gru/dispatch.md): the seven-step minion flow, ground rules, Godot session tiers, paired dispatch shapes, error recovery, and the "what's in flight" queries that replace the old shared board. **Read before starting any ticketed work if another agent may be active.**
- [skills/minions/commits.md](skills/minions/commits.md): branch and commit discipline (DCO sign-off, no rebase, no amend, fresh branch after merge, ggut after every change).
- [skills/minions/reviewers.md](skills/minions/reviewers.md): reviewer fan-out by changed path, verdict shape, label flips, race resolver.
- [STYLE.md](STYLE.md): writing style guide for long-form prose (docs, essays, devlogs). Read before drafting any written content.

## Conventions

- One agent per ticket, one agent per file. Concurrent writes silently overwrite.
- Escalate to Josh after two different strategies fail on the same issue. Not three.
- Every change needs evidence: tool output or tests, never "looks correct".
- Follow `/home/josh/gamedev/volley/CLAUDE.md` for tool choice and workflow.
