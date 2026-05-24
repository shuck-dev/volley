# Flow shapes, bug, spike, feature

Three mission shapes. Each has a distinct entry, a distinct deliverable, and a distinct "done."

Pick the shape before the codename. Dispatching the wrong shape adds overhead (planner for a one-line typo) or misses verification (no repro for a player-visible bug).

Pairs with [`missions-and-projects.md`](missions-and-projects.md) (the nouns) and [`dandori.md`](dandori.md) (the planning interrogation).

## Bug

A defect the player can hit in real gameplay.

**Entry.** Exact repro from the player. Save state at start, sequence of inputs, expected vs actual, which surface the symptom appears on. Prior diagnoses and handoff notes are context, not a recipe; ask for the recipe before any RCA.

**Shape.** Single implementer, or RCA-then-implementer pair. No tech doc, no refactor-planner. RCA tier ladder: static trace → runtime → devil's-advocate → Josh-in-loop, bumping on each genuine failure.

**Deliverable.** A fix plus a test that mirrors the repro.

**Done when.** The repro stops producing the symptom in a real game session.

**Smell that this is the wrong flow.** If the "fix" turns out to need cross-system architecture, stop and escalate. The work is no longer a bug; it's a feature or a refactor.

## Spike

A question that can't be answered without exploring code, prototyping, or research.

**Entry.** The question, time-boxed. "Is the AI prediction good enough for two balls?" is a spike. "Can we use Godot 4.5's new audio bus features?" is a spike. "Walk the new contributor onboarding cold and see where it breaks" is a spike.

**Shape.** A writeup in [`ai/scratchpads/`](../../ai/scratchpads) by default (promoted to [`designs/research/`](../research/) only when the work earns it) and often a throwaway prototype branch. The prototype is for evidence, not for merging.

**Deliverable.** **Feature issues filed in Linear.** The writeup is a vehicle; the tickets are what carries the value forward. A spike that ends without feature issues is unfinished, the question got answered, but nothing acts on the answer.

**Done when.** Linear has the tickets the spike's findings unlocked.

**Smell that this is the wrong flow.** If the question is small enough to answer with a single grep or a quick read, just answer it inline. If the prototype is going to ship, promote to a feature mission and re-dispatch under that shape.

## Feature

A player-facing capability or a refactor whose blast radius crosses multiple files or systems.

**Entry.** The player-facing outcome the player should see when it's done.

**Shape.** Five phases:

1. **Frame.** Name the player-visible outcome.
2. **Design pass.** End-state architecture in a tech doc under [`designs/01-prototype/tech/`](../01-prototype/tech/); player-facing design (if separate) under [`designs/01-prototype/design/`](../01-prototype/design/). Decisions land in the doc, not in chat.
3. **Planner dispatch.** A planner agent produces a sequenced plan with blast-radius analysis, scoped per PR. Open design calls surface as recommendations; the dispatcher carries them to Josh. Plan saved to scratchpads. Decisions folded back into the plan after Josh picks.
4. **Implementer fan-out.** Each plan step gets one implementer minion, codenamed, dispatched in the background. Each minion branches from the previous step's branch (PRs stack), ships a draft, runs static + GUT, returns a report. Coupled PRs stay draft until their base merges.
5. **Fold and Ride.** When the stack is ready, the dispatcher merges into the parent feature branch (or main if no parent). GitHub auto-closes the sub-PRs when their commits land. Worktrees pruned, refactor branches deleted. The mission closes with the Ride, Josh-as-pilot validates player-feel at runtime.

**Deliverable.** The capability shipped end-to-end, the tech doc reflecting the landed system, sub-tickets closed, Ride passed.

**Done when.** The player can use the capability in real gameplay. The Ride confirms feel, not just function.

**Smell that this is the wrong flow.** If the work is single-file with a clear repro, drop the planner overhead, it's a bug. If the work is "we don't know how X should work," output should be tickets, not code, it's a spike.

## Reporting discipline (cross-flow)

Every progress report opens with the player-visible status, not the architectural deliverable. "Foundations 3/6 complete; bug not yet visible-fixed" is the right shape until the load-bearing step lands. "Stack landed" is not a status; the status is whether the player can still hit the bug.

## Choosing the flow

- One-file fix with a clear repro → **bug**.
- "We don't know how X should work" / "is Y feasible?" → **spike**.
- "Build / refactor X across files" with a known target shape → **feature**.

Name the flow out loud before dispatch. The codename comes after.

## Cascades

Flows feed each other. Each handoff is a flow boundary; pick the new flow's shape, not the old one's.

- A spike's tickets launch a feature mission.
- A feature mission spawns bug-fix follow-ups.
- A bug fix reveals an architectural smell that becomes a spike, which becomes a feature.

The handoff is the natural break point. Don't carry a half-baked spike into feature work without filing the tickets; don't carry a single-file bug into feature work without checking whether the bug is the whole job.
