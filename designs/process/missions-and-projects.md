# Missions, rides, projects, cycles

The four nouns that organise work in Volley, and how they relate.

## Mission

A scoped goal with a codename, surfaced as a **Linear milestone** in its owning project. The milestone name is the mission codename.

The codename is opaque (e.g. **Kyle Patrol**, **Page One**) per the Gru-canon convention: CIA-style two-word handles from the DM/Minions lexicon, the codename doesn't leak the mission's content. The milestone description does.

A project owns at most one active mission at a time, which means at most one active milestone per project. When the mission completes, the milestone closes and the project picks up the next one.

A mission can have multiple rides if the first attempt is retired. The milestone persists across rides; ride codenames rotate.

**To find the current mission**, read the project's active milestone. **To find what's in flight across the team**, read active milestones across the active projects.

The Ride ticket and the work tickets that unblock the Ride all set their `milestone` field to the mission milestone, so the milestone's progress reflects what's left to land.

## Ride

The playtest verification beat of a mission. A Linear ticket with the `ride` label. Carries player-observable acceptance criteria; code-inspection findings file as separate Battle or code-review tickets.

Ride structure:

- **Title:** `Ride: <codename>`
- **Body:** user story (as a player / I want / so that), then ACs.
- **Codename:** matches the mission codename on the first ride; rotates on subsequent rides under the same mission (e.g. mission Kyle Patrol → first ride "Kyle Patrol", second ride "Stuart Stride").
- **Project:** the project that owns the player-observable verification surface.

A ride retires (cancels) when its findings overflow into a backlog of work; the new ride for the same mission references the retired one in its body.

A mission completes when a ride's ACs pass cleanly (or with reasonable filed follow-ups).

## Project

A Linear project. Linear-shaped: name, summary, description, status, milestones, issues. Holds the regular work tickets (features, bugs, spikes, studies).

Projects are **linear in scope**: the work inside a project completes inside the project. If a ticket in this project depends on a ticket in another project to finish, the project boundary is wrong.

When the boundary is leaking, resolve by:

- Moving the dependency ticket into this project (it belongs here).
- Moving this project's ticket into the depending project (it belongs there).
- Merging the two projects (their scopes overlap enough that the boundary is artificial).

Don't carry a cross-project dependency as a known thing. Treat it as a structural smell.

Shared infrastructure (utilities, the engine, generic helpers) is fine across projects. Cross-project tickets unblocking each other is the smell.

## Cycle

A Linear cycle. Time-bounded (Tuesday → Monday). Holds whatever work is targeted to land in that span.

A cycle is goal-oriented: its description names what the cycle wants to complete. The natural framing is "this cycle completes the missions of these projects." Cycle status updates report against that goal.

## How they relate

- A **cycle** holds tickets from multiple projects.
- Each **project** has at most one active **mission**, surfaced as the project's active **milestone**.
- The mission's verifiable target is its **ride**, a ticket in the project with the `milestone` field set to the mission milestone.
- Other tickets unblocking the ride also point at the same milestone; the milestone's progress reflects what's left.
- Findings from the ride file as tickets in the same project (or escalate to a different project's scope, which signals a missed boundary).
- The cycle completes the mission when the ride passes; the milestone closes; the project picks up the next mission.

## Worked example

**Cookie Monster cycle, 2026-04-19 → 2026-05-03.** The cycle wants to complete Kyle Patrol (Equip Loop's mission).

- Project: **Equip Loop**
- Mission: **Kyle Patrol** (codename, no ticket)
- First ride: SH-228 (`Ride: Kyle Patrol`), retired when findings overflowed; bugs filed (SH-251, SH-252, SH-258, SH-260, SH-261, SH-262)
- Second ride: SH-296 (`Ride: Stuart Stride`), Ready, in cycle
- The cycle's other Equip Loop tickets (SH-287, SH-288, SH-289, SH-290) all live inside Equip Loop because they unblock Stuart Stride's ACs; Kyle Patrol's mission completes when Stuart Stride passes.
