# Flow shapes — bug, spike, feature

Three mission shapes. Each has a distinct entry, deliverable, and "done."

Pick the shape before the codename. The shape decides what work earns the planner, the tech doc, the Ride.

Pairs with [`missions-and-projects.md`](missions-and-projects.md) (the nouns) and [`dandori.md`](dandori.md) (the planning interrogation).

## Bug

A defect the player can hit in real gameplay.

**Entry.** Exact repro from the player: save state at start, sequence of inputs, expected vs actual, the surface the symptom appears on. The recipe comes from the player; ask before any RCA.

**Shape.** Straight to implementer, or RCA-then-implementer for the harder ones. RCA tier ladder: static trace → runtime → devil's-advocate → Josh-in-loop, bumping on each genuine failure.

**Deliverable.** A fix plus a test that mirrors the repro.

**Done when.** The repro stops producing the symptom in a real game session.

**Smell that this is the wrong flow.** A "fix" that turns out to need cross-system architecture has become a feature or a refactor. Stop and escalate.

## Spike

A question that needs exploration to answer — code, prototype, or research.

**Entry.** The question, time-boxed. "Is the AI prediction good enough for two balls?" is a spike. "Can we use Godot 4.5's new audio bus features?" is a spike. "Walk the new contributor onboarding cold and see where it breaks" is a spike.

**Shape.** A writeup in [`ai/scratchpads/`](../../ai/scratchpads) by default (promoted to [`designs/research/`](../research/) only when the work earns it) plus a throwaway prototype branch if useful. The prototype is for evidence.

**Deliverable.** **Feature issues filed in Linear.** The writeup is a vehicle; the tickets carry the value forward. A spike closes with tickets in hand.

**Done when.** Linear has the tickets the spike's findings unlocked.

**Smell that this is the wrong flow.** A question that resolves with one grep or a quick read gets answered inline. A prototype that wants to ship lifts to a feature mission and re-dispatches under that shape.

## Feature

A player-facing capability or a refactor whose blast radius crosses multiple files or systems.

**Entry.** The player-facing outcome the player should see when it's done.

**Shape.** Five phases:

1. **Frame.** Name the player-visible outcome.
2. **Design pass.** End-state architecture in a tech doc under [`designs/01-prototype/tech/`](../01-prototype/tech/); player-facing design (if separate) under [`designs/01-prototype/design/`](../01-prototype/design/). Decisions land in the doc.
3. **Planner dispatch.** A planner agent produces a sequenced plan with blast-radius analysis, scoped per PR. Open design calls surface as recommendations; the dispatcher carries them to Josh. Plan saved to scratchpads. Decisions fold back into the plan after Josh picks.
4. **Implementer fan-out.** Each plan step gets one implementer minion, codenamed, dispatched in the background. Each minion branches from the previous step's branch (PRs stack), ships a draft, runs static + GUT, returns a report. Coupled PRs stay draft until their base merges.
5. **Fold and Ride.** When the stack is ready, the dispatcher merges into the parent feature branch (or main if no parent). GitHub auto-closes the sub-PRs as their commits land. Worktrees pruned, refactor branches deleted. The mission closes with the Ride — Josh-as-pilot validates player-feel at runtime.

**Deliverable.** The capability shipped end-to-end, the tech doc reflecting the landed system, sub-tickets closed, Ride passed.

**Done when.** The player can use the capability in real gameplay. The Ride confirms feel, beyond function.

**Smell that this is the wrong flow.** A single-file change with a clear repro belongs in the bug flow; drop the planner. An open question whose answer is still being shaped belongs in the spike flow; the output is tickets.

## Reporting discipline (cross-flow)

Every progress report opens with the player-visible status. "Foundations 3/6 complete; visible fix lands at step 5" is the right shape until the load-bearing step lands. "Stack landed" describes architectural progress; the status is whether the player can still hit the bug.

## Choosing the flow

- One-file fix with a clear repro → **bug**.
- "We're unsure how X should work" / "is Y feasible?" → **spike**.
- "Build / refactor X across files" with a known target shape → **feature**.

Name the flow out loud before dispatch. The codename comes after.

## Cascades

Flows feed each other. Each handoff is a flow boundary; pick the new flow's shape rather than carrying the old one's.

- A spike's tickets launch a feature mission.
- A feature mission spawns bug-fix follow-ups.
- A bug fix reveals an architectural smell that becomes a spike, which becomes a feature.

The handoff is the natural break point. File the spike's tickets before any feature work follows. Check whether a bug is the whole job before lifting it to feature scope.
