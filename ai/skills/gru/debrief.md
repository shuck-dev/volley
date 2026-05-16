---
name: debrief
description: Scrum-style process retrospective on a mission, swarm, ride, or session. Looks back at blockers, improvements, and the action items that come out of those. NOT a report on what shipped. Read on "debrief", "mission complete", "retro", "wrap-up", "done with X".
---

# Debrief

A debrief is a retrospective on **how the work happened**: the process, the blockers, the improvements for next time. It is not a report on **what shipped**. What shipped lives in the PR list, the commit history, the milestone close note. The debrief leaves that alone.

The shape is scrum-style. Open with blockers, name the improvements they earn, route the action items, list flags, post. The discipline lives across six memory files; this skill is the assembly point so the orchestrator hits all six at once.

## Checklist

```
[ ] 1. git status + git branch --show-current; name dirty or clean.
       feedback_git_status_before_debrief
[ ] 2. Dispatch three independent agents in parallel (cold-read, devils-advocate, CI miner).
       feedback_debrief_source_linear_and_devils
[ ] 3. Fold drafts. The orchestrator does not write the draft itself.
       feedback_debrief_source_linear_and_devils
[ ] 4. Frame the body as process retro: Blockers, Improvements, Action items, Flags.
       Strip any "what shipped" headline; that is a status report, not a debrief.
       feedback_debrief_is_process_retro_not_status_report
[ ] 5. Post via mcp__linear__save_status_update on the relevant project.
       feedback_debrief_source_linear_and_devils, feedback_swarm_retro
[ ] 6. Route every action item Filed / Memory-only / Parked.
       feedback_debrief_action_items
[ ] 7. List every flag added during the mission, or state "none".
       feedback_flags_surface_or_skip
```

## Body sections

- **Blockers.** What slowed the work down. Reviewer round-trips, wrong-shape PRs, repeated voice corrections, surface-state bleeds, advisory-not-blocking caveats that turned out to be load-bearing. Named concretely with PR / SHA citations.
- **Improvements.** What is different now. Memory rules added or sharpened, skills consolidated, hooks added. Each improvement names the blocker it addresses.
- **Action items.** Process levers, NOT deliverable follow-ups. A new memory rule, a new skill, a new hook, a new convention, a new audit pass over existing artefacts. "Sweep the suite for tautology smells", "tighten the hook regex", "amend the reviewer brief to escalate global-state caveats." NOT "file SH-405 AC #4" or "rewrite the oscillator test"; those are next-mission backlog, not retro material. Action items compound; deliverable follow-ups grow linearly. Filed / Memory-only / Parked per `feedback_debrief_action_items`.
- **Flags.** Per `feedback_flags_surface_or_skip`: every flag added during the mission, or "none added" explicitly.

What does NOT belong in a debrief: a "what shipped" headline, a PR list narrating the deliverables, a milestone-close summary. Those are status report content. A debrief that opens with merge counts and feature names is a self-flattering status report wearing a retro label.

## Triggers

Read this skill when the user prompt or task notification names any of: `debrief`, `mission complete`, `mission close`, `wrap up`, `retro`, `done with X`. The UserPromptSubmit hook at `~/.claude/hooks/debrief-flow-signal.sh` injects a reminder when the trigger phrase appears.
