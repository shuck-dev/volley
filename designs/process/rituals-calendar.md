# Rituals calendar

The cadence the named rituals run on. Ritual definitions live in `ai/lair/guide.md`; cycle shape lives in `project-management.md`. This doc lands the calendar.

## Two Mondays per cycle

Shuck cycles are two weeks long, Tuesday to Monday. Each cycle has two ritual Mondays. Each one carries one heavy ritual; they do not stack.

### Mid-cycle Monday (day 7)

The build's Monday.

- **Morning: Carnival.** Full playtest gate on the assembled build. The three Gru Sisters are dispatched and take the whole game from their own angle. Carnival passes when each sister has nodded.
- **Afternoon: Return.** Prod deploy of the build Carnival just cleared. If Carnival surfaces a blocking finding, the deploy waits and fix work becomes the priority for week two.

If Carnival clears clean, the rest of week two is for the next cycle's setup work and any milestone-shaped release that earned its own moment.

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
