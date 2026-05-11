# Carnival ticket template

Skeleton for every cycle's Carnival ticket. The scheduled routine (or a manual cycle-start filing) saves a new Linear issue using this body, with the cycle name substituted and the due date set to that cycle's mid-cycle Monday. Planning fills in the specifics.

## Title

`<Cycle name> Carnival`

Example: `Doglion Carnival`, `Elmo Carnival`.

## Body

```markdown
PLAYTEST the player-facing changes that landed in cycle `<Cycle name>`.
So that the Return that follows in the afternoon ships a build the Gru Sisters have nodded on.

What this Carnival is testing:
- TO FILL IN AT PLANNING: the player-facing changes that landed since the previous cycle's deploy. Not the whole game; whole-game regression is the per-PR Battle's job. Carnival reads the deltas in the player's hand.

Where the Gru Sisters should focus:
- TO FILL IN AT PLANNING: Margo (analytical, systems and edges), Edith (break-it, abuse vectors), Agnes (the felt experience, the hand on the controller).

**Acceptance Criteria:**

- [ ] Margo's pass: report posted, blockers flagged, non-blockers filed as bugs against next cycle
- [ ] Edith's pass: report posted, blockers flagged, non-blockers filed as bugs against next cycle
- [ ] Agnes's pass (Josh on the controller): report posted, blockers flagged, non-blockers filed as bugs against next cycle
- [ ] Carnival nod from all three before Return is dispatched
- [ ] If blocked: deploy waits, fix work becomes the priority for week two, Return slot rolls to next cycle's mid-cycle Monday
```

## Linear fields

- Project: none (Carnival is cycle-wide, not project-scoped); leave unattached.
- Cycle: the current cycle. The routine sets this from `list_cycles`.
- Status: Vault on file, promotes to Ready when planning fills in the specifics.
- Label: `carnival` (id `80f70f1a-afce-4873-b7ae-e7f7c4d0baa0`).
- Assignee: leave unassigned; assign Josh when the ticket enters the active cycle per `feedback_assign_in_cycle_only`.
- Due date: the cycle's mid-cycle Monday (day 7 of 14, the Monday halfway through the cycle).
- Links: any `designs/process/*.md` docs that anchor the ritual.

## Calculation: mid-cycle Monday from a cycle

A cycle starts Tuesday `T` and ends Monday `T + 13` (the buffer day). The mid-cycle Monday is `T + 6`, the Monday at the halfway point, day 7 of the cycle counted from day 1.

```python
from datetime import date, timedelta
mid_cycle_monday = cycle.starts_at.date() + timedelta(days=6)
```

Use `mcp__linear__list_cycles type=current` to fetch `startsAt` for the active cycle.
