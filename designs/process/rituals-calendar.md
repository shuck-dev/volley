# Rituals calendar

The cadence Volley runs on, written as part of the open-development practice the studio leans into. Anyone reading the repo can see when builds ship, when code gets reviewed, and when the studio looks back at what landed. The named rituals (Carnival, Return, Battle, Ride) are defined in `ai/lair/guide.md`; cycle mechanics live in `project-management.md`. This doc lands the calendar they fire on.

## Two Mondays per cycle

Shuck cycles are two weeks long, Tuesday to Monday. Each cycle has two ritual Mondays.

### Mid-cycle Monday (day 7): Carnival and Return

Halfway through the cycle, the build is played end-to-end and released to the public.

- **Morning: Carnival.** A focused playtest gate against the player-facing changes that landed since the previous Return. Three angles run in parallel: a systems read, an abuse-vector pass, and a feel pass on the controller. Whole-game regression is the Battle's job during the cycle; the Carnival reads the deltas.
- **Afternoon: Return.** If the Carnival passes, the build deploys to production the same afternoon. Each cycle has one routine Return on its mid-cycle Monday. If the Carnival surfaces a blocking finding, the Return waits, fix work becomes the priority for week two, and the slot rolls to the next cycle's mid-cycle Monday.

If the Carnival clears, week two continues with the cycle's in-flight work. The cycle continues; the Return is mid-cycle, the plan is end-cycle. Week two carries the work that will land in the next cycle's Return.

### Cycle-close Monday (day 14): retro and plan

The end of the cycle. No Return; the focus is on closing this cycle and shaping the next one.

- **Retro.** Look back. What landed, what stuck, what process changes the studio wants to keep.
- **Plan.** Look forward. Ready the next cycle's issues, name the new cycle, set its description.

## Between the Mondays

The Mondays carry the heavy rituals. The rest of the cycle runs the continuous ones, which fire per pull request or per feature: the Battle (per-PR review) and the Ride (per-feature smoke test). A cycle whose Battles and Rides were clean is the cycle most likely to clear its mid-cycle Carnival.

## What rolls forward

Work that misses a cycle's Return slot rolls into the next cycle's Return slot. The Tuesday-to-mid-cycle-Monday window of the new cycle is the next chance to ride the coaster; the second-half window of the current cycle is the one after that.

## How the Carnival issue lands

Linear's recurring-issue feature fires the Carnival issue every cycle on the cycle-start Tuesday. The body, the `carnival` label, and the due-date offset (`+6 days` from creation, landing the mid-cycle Monday) all live in the Linear recurring-issue config. Planning fleshes out the fired issue: what this cycle's Carnival is covering, where the testing focus should land, what player-facing changes the build carries.

## Hotfixes

Hotfixes ship when needed, on any day, on their own clock, and supersede the routine Return. A hotfix moves to production the moment it's clean, regardless of where the cycle is in its calendar. The routine Return continues on its slot once the hotfix is out.
