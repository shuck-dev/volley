# ai/

Coordination for AI agents working on this repo. Not design, not code: operational state.

## Files

- [PARALLEL.md](PARALLEL.md): parallel processing coordination. Claim tickets, log status, escalate early, Godot edge-case checklist. **Read before starting any ticketed work if another agent may be active.**
- [STYLE.md](STYLE.md): writing style guide for long-form prose (docs, essays, devlogs). Read before drafting any written content.

## Conventions

- One agent per ticket, one agent per file. Concurrent writes silently overwrite.
- Escalate to Josh after two different strategies fail on the same issue. Not three.
- Every change needs evidence: tool output or tests, never "looks correct".
- Follow `/home/josh/gamedev/volley/CLAUDE.md` for tool choice and workflow.
