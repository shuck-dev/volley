---
name: debrief
description: How to wrap a mission, swarm, ride, or session. Read on "debrief", "mission complete", "retro", "wrap-up", "done with X". Six-step checklist; each step points at the memory file that owns the rule body.
---

# Debrief

A debrief is the closing pulse on a chunk of work. The discipline lives across five memory files; this skill is the assembly point so the orchestrator hits all five at once instead of one-at-a-time. Each step below names the action; the load-bearing detail lives in the linked memory.

## Checklist

```
[ ] 1. git status + git branch --show-current; name dirty or clean.
       feedback_git_status_before_debrief
[ ] 2. Dispatch three independent agents in parallel (cold-read, devils-advocate, CI miner).
       feedback_debrief_source_linear_and_devils
[ ] 3. Fold drafts. The orchestrator does not write the draft itself.
       feedback_debrief_source_linear_and_devils
[ ] 4. Post via mcp__linear__save_status_update on the relevant project.
       feedback_debrief_source_linear_and_devils, feedback_swarm_retro
[ ] 5. Route every action item Filed / Memory-only / Parked.
       feedback_debrief_action_items
[ ] 6. List every flag added during the mission, or state "none".
       feedback_flags_surface_or_skip
```

## Triggers

Read this skill when the user prompt or task notification names any of: `debrief`, `mission complete`, `mission close`, `wrap up`, `retro`, `done with X`. The UserPromptSubmit hook at `~/.claude/hooks/debrief-flow-signal.sh` injects a reminder when the trigger phrase appears.
