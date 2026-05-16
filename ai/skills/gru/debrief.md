---
name: debrief
description: How to wrap a mission, swarm, ride, or session. Read on "debrief", "mission complete", "retro", "wrap-up", "done with X". Six-step flow that ends with a project status update on Linear, not inline prose.
---

# Debrief

A debrief is the closing pulse on a chunk of work. It is not a self-flattering orchestrator summary, and it does not live in conversation prose. The discipline below consolidates five memory rules that fired round after round in past sessions.

## Six-step flow

Read top-to-bottom before producing any debrief text.

```
[ ] 1. git status + git branch --show-current. Name what's dirty or "clean".
[ ] 2. Dispatch three agents in parallel, briefed not to read each other's drafts:
       - cold-read agent: surveys open / closed PRs, Linear state, commits
       - devils-advocate: stress-tests what shipped, names blind spots
       - CI miner: scrapes commit history and diffs for patterns
[ ] 3. Fold the three drafts. Never write the orchestrator's draft yourself;
       the orchestrator is in the seat that biased the work and lacks distance.
[ ] 4. Post via mcp__linear__save_status_update(type: "project", project: <id>)
       on the relevant project. NEVER as save_comment on issues, even when
       issues lack a parent. Cross-cutting work goes on Swarm Hardening.
[ ] 5. Action items section: every follow-up routed Filed / Memory-only / Parked.
       No unstructured prose. If nothing, say "No follow-up issues required."
[ ] 6. Flags section: list every flag added during the mission, or "none added"
       explicitly. Flags that lived 10 commits and got deleted still get named.
```

## What goes in each section

- **Headline.** What the mission shipped, in one sentence. State-assertion-shaped: "Equip flow with kit cap now ships through the rack-equip pose".
- **What shipped.** Concrete PRs / issues / merged work, with links. The cold-read agent compiles this.
- **What got blocked / descoped / wasted time.** The devils-advocate's reading. The orchestrator's draft underweights this every time.
- **Patterns from the CI / commit history.** The miner's reading. Flag misnomers (per `feedback_flags_surface_or_skip`), redundant rounds, late-landed reviewer findings.
- **Action items.** Each item gets one routing:
  - **Filed**: issue ID + URL inline. Confirm with Josh first unless the finding is from a Gru Sister (Margo / Edith) on a Ride or Carnival (per `feedback_auto_issue_verified_sister_findings`).
  - **Memory-only**: named with the memory file that captures the rule, no issue needed.
  - **Parked**: explicit defer with a reason and who reopens.
- **Flags.** Per `feedback_flags_surface_or_skip`. List every flag, even retired ones. "None added" is the default and gets stated.
- **Lessons worth carrying forward.** Narrative; what to do differently next time.

## Surface choice

| Mission scope | Project to post on |
|---|---|
| Single ticket / feature mission | The mission's project (e.g. Equip Loop) |
| Cycle-scope or cross-cutting | Swarm Hardening (agent-infra) |
| Ride / Carnival output | The mission's project (player-facing) plus issues filed on Swarm Hardening for non-player findings |

The milestone description stays the short brief statement it opened with. The debrief lives as a long-form status update; it is not the milestone description.

## Agent briefs (for step 2)

Each agent's brief explicitly:

- Names "no em dashes" per `feedback_no_em_dashes`. The rule does not propagate unless stated; debrief text lands verbatim on Linear.
- Tells the agent not to read any existing debrief draft. Independence is the load-bearing property.
- Names the agent's specific lens (cold-read, devils-advocate, miner). One per agent; do not blur them.
- Asks for plain prose findings, not a finished debrief draft.

## Failure modes the rules exist to kill

- **Self-flattering orchestrator draft.** Emphasises codenames dispatched and rules added; underweights what got blocked and what wasted time.
- **Wrong surface.** Per-issue `save_comment` instead of project `save_status_update`. The pulse is project-scope.
- **Silent dirt.** Tree was dirty when "mission complete" was posted; Godot drive-by re-imports or stash residue.
- **Action items as unstructured prose.** "Service-account work is its own future issue when prioritised" is how an item vanishes.
- **Flags glossed over.** A flag that lived ten commits and got retired before merge is still a flag worth naming.

## Memory rules consolidated here

- `feedback_git_status_before_debrief`
- `feedback_debrief_source_linear_and_devils`
- `feedback_swarm_retro`
- `feedback_debrief_action_items`
- `feedback_flags_surface_or_skip`

Each of those memories is the load-bearing source. This skill is the assembly point so the orchestrator hits all five at once rather than one-at-a-time.
