# Rituals calendar

The cadence the named rituals run on. Ritual definitions live in `ai/lair/guide.md`; cycle shape lives in `project-management.md`. This doc lands the calendar.

## Two Mondays per cycle

Shuck cycles are two weeks long, Tuesday to Monday. Each cycle has two ritual Mondays. Each one carries one heavy ritual; they do not stack.

### Mid-cycle Monday (day 7)

The build's Monday.

- **Morning: Carnival.** Playtest gate focused on the player-facing changes that landed since the previous cycle's deploy. The three Gru Sisters are dispatched and take those changes from their own angle. Carnival passes when each sister has nodded. Whole-game regression is the per-PR Battle's job; Carnival reads the cycle's deltas in the player's hand.
- **Afternoon: Return.** Prod deploy of the build Carnival just cleared. If Carnival surfaces a blocking finding, the deploy waits and fix work becomes the priority for week two.

If Carnival clears clean, week two continues with the cycle's in-flight work. The cycle hasn't ended; the deploy is mid-cycle, the plan is end-cycle. Week two carries the work that will land in the next cycle's mid-cycle Carnival.

## Between the Mondays

The Mondays carry the heavy rituals. The rest of the cycle runs the continuous ones, which are per-PR or per-feature rather than per-cycle.

- **Battle.** The adversarial review round inside every Dandori Challenge. Runs whenever a PR opens. Reviewer minions post verdicts; blocks supersede approves; the Battle resolves when the diff is clean and Josh signs off. The build entering Carnival is presumed to have cleared its Battles.
- **Ride.** Single-feature smoke test on a merged build after a Challenge lands. Per feature, not per cycle. The Ride confirms the feature reads right in-game before the next mission opens.

A cycle whose Battles and Rides were clean is the cycle most likely to clear its mid-cycle Carnival.

### Cycle-close Monday (day 14)

The plan's Monday.

- **Retro.** Look back at the cycle. What landed, what stuck, what new memory rules want filing.
- **Plan.** Look forward. Promote the next cycle's tickets to Ready, name the new cycle's letter, set its description.

No Carnival on cycle-close. No deploy on cycle-close. Retros and testing are both heavy enough that stacking them onto the same day corrupts the focus of both.

## What rolls forward

Work that misses a cycle's mid-cycle deploy slot rolls into the next cycle's mid-cycle deploy slot. The Tuesday-to-mid-cycle-Monday window of the new cycle is the next chance to ride the train; the second-half window is week two of the same cycle, which feeds the cycle after that.

## How the Carnival ticket gets filed

Every cycle has its Carnival ticket pre-filed. The skeleton is a template (label `carnival`, due date day 7, placeholder AC scaffolding); the specifics get written during planning. Two viable paths:

- **Scheduled routine.** A cron-driven agent fires on the cycle-start Tuesday, computes the mid-cycle Monday from `mcp__linear__list_cycles`, and saves the Carnival ticket with the template body. Planning fills in what this cycle's Carnival is testing.
- **Tuesday-morning manual filing.** First action of every cycle-start Tuesday is filing that cycle's Carnival ticket from the same template.

The schedule path is cleaner once the template is stable. Until then, manual filing as part of cycle kickoff is fine.

## Hotfixes and milestones

- **Hotfixes ship any day.** They are not part of the cycle calendar.
- **Milestone releases.** The decision *whether* to release is milestone-based per `feedback_milestone_releases`. The calendar slot is still mid-cycle Monday; a milestone that is ready borrows that slot and the cycle's routine Carnival takes the release-candidate posture for the day.
