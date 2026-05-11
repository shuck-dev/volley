# Rituals calendar

The development cadence Volley runs on, written as part of the open-development practice the studio leans into. Anyone reading the repo can see when builds ship, when work is reviewed, and when the studio looks back at what landed. The internal vocabulary that sits over the top is described in `ai/lair/guide.md`; cycle mechanics live in `project-management.md`.

## Two Mondays per cycle

Shuck cycles are two weeks long, Tuesday to Monday. Each cycle has two ritual Mondays.

### Mid-cycle Monday (day 7): playtest and release

Halfway through the cycle, the build is played end-to-end and released to the public.

- **Morning: playtest.** A focused playtest gate against the player-facing changes that landed since the previous release. Three angles run in parallel: a systems read, an abuse-vector pass, and a feel pass on the controller. Whole-game regression is covered by per-PR review during the cycle; this gate reads the deltas.
- **Afternoon: release.** If the playtest gate passes, the build deploys to production the same afternoon. Each cycle has one routine release on its mid-cycle Monday. If the playtest gate surfaces a blocking finding, the release waits, fix work becomes the priority for week two, and the slot rolls to the next cycle's mid-cycle Monday.

If the gate passes, week two continues with the cycle's in-flight work. The cycle continues; the release is mid-cycle, the plan is end-cycle. Week two carries the work that will land in the next cycle's release.

### Cycle-close Monday (day 14): look back and look forward

The end of the cycle. No release; the focus is on closing this cycle and shaping the next one.

- **Retro.** Look back. What landed, what stuck, what process changes the studio wants to keep.
- **Plan.** Look forward. Ready the next cycle's issues, name the new cycle, set its description.

## Between the Mondays

The Mondays carry the heavy rituals. The rest of the cycle runs the continuous ones, which fire per pull request or per feature: the Battle (per-PR review) and the Ride (per-feature smoke test). Both are defined in `ai/lair/guide.md`.

A cycle whose Battles and Rides were clean is the cycle most likely to clear its mid-cycle playtest gate.

## What rolls forward

Work that misses a cycle's mid-cycle release slot rolls into the next cycle's mid-cycle release slot. The Tuesday-to-mid-cycle-Monday window of the new cycle is the next chance to ride the coaster; the second-half window of the current cycle is the one after that.

## How the cycle's playtest issue lands

Linear's recurring-issue feature fires the playtest issue every cycle on the cycle-start Tuesday. The body, the label, and the due-date offset (`+6 days` from creation, landing the mid-cycle Monday) all live in the Linear recurring-issue config. Planning fleshes out the fired issue: what this cycle's playtest is covering, where the testing focus should land, what player-facing changes the build carries.

## Hotfixes

Hotfixes ship when needed, on any day, on their own clock, and supersede the routine cycle release. A hotfix moves to production the moment it's clean, regardless of where the cycle is in its calendar. The routine release continues on its slot once the hotfix is out.
