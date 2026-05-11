# Rituals calendar

The cadence the named rituals run on. Ritual definitions live in `ai/lair/guide.md`; cycle shape lives in `project-management.md`. This doc lands the calendar.

## Two Mondays per cycle

Shuck cycles are two weeks long, Tuesday to Monday. Each cycle has two ritual Mondays. Each one carries one heavy ritual; the rituals stay on their own day.

### Mid-cycle Monday (day 7)

The build's Monday.

- **Morning: Carnival.** Playtest gate focused on the player-facing changes that landed since the previous cycle's deploy. The three Gru Sisters are dispatched and take those changes from their own angle. Carnival passes when each sister has nodded. Whole-game regression is the per-PR Battle's job; Carnival reads the cycle's deltas in the player's hand.
- **Afternoon: Return.** Prod deploy of the build Carnival just cleared. Each cycle ships its mid-cycle Monday deploy as the routine release; the question of *what* ships is whatever player-facing changes landed since the previous cycle's deploy. If Carnival fails, the deploy waits, fix work becomes the priority for week two, and the slot rolls to the next cycle's mid-cycle Monday.

If Carnival clears, week two continues with the cycle's in-flight work. The cycle continues; the deploy is mid-cycle, the plan is end-cycle. Week two carries the work that will land in the next cycle's mid-cycle Carnival.

### Cycle-close Monday (day 14)

The plan's Monday.

- **Retro.** Look back at the cycle. What landed, what stuck, what new memory rules want filing.
- **Plan.** Look forward. Promote the next cycle's issues to Ready, name the new cycle's letter, set its description.

## Between the Mondays

The Mondays carry the heavy rituals. The rest of the cycle runs the continuous ones, which are per-PR or per-feature rather than per-cycle.

- **Battle.** The adversarial review round inside every Dandori Challenge. Runs whenever a PR opens. Reviewer minions post verdicts; blocks supersede approves; the Battle resolves when the diff is clean and Josh signs off. The build entering Carnival is presumed to have cleared its Battles.
- **Ride.** Single-feature smoke test on a merged build after a Challenge lands. Per feature, not per cycle. The Ride confirms the feature reads right in-game before the next mission opens.

A cycle whose Battles and Rides were clean is the cycle most likely to clear its mid-cycle Carnival.

## What rolls forward

Work that misses a cycle's mid-cycle deploy slot rolls into the next cycle's mid-cycle deploy slot. The Tuesday-to-mid-cycle-Monday window of the new cycle is the next chance to ride the coaster; the second-half window is week two of the same cycle, which feeds the coaster after that.

## How the Carnival issue lands

Linear's recurring-issue feature fires the Carnival issue every cycle on the cycle-start Tuesday. The body, the label (`carnival`), and the due-date offset (`+6 days` from creation, landing the mid-cycle Monday) all live in the Linear recurring-issue config. Planning fleshes out the fired issue: what this cycle's Carnival is testing, where the Gru Sisters should focus, what player-facing changes the build carries.

## Hotfixes

Hotfixes ship when needed, on any day, on their own clock, and supersede the routine cycle release. A hotfix moves to prod the moment it's clean, regardless of whether the cycle's Carnival has fired or whether the mid-cycle Monday has arrived. The cycle release continues on its calendar slot once the hotfix is out.
