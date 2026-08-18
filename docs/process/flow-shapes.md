# Flow shapes, bug, spike, feature

Three flow shapes. Each has a distinct entry, a distinct deliverable, and a distinct "done."

Pick the shape before starting. The wrong shape adds overhead (a full design pass for a one-line typo) or misses verification (no repro for a player-visible bug).

## Bug

A defect the player can hit in real gameplay.

**Entry.** Exact repro from the player. Save state at start, sequence of inputs, expected vs actual, which surface the symptom appears on. Prior diagnoses and handoff notes are context, not a recipe; ask for the recipe before any root-cause analysis.

**Shape.** A single change, sometimes a root-cause investigation first. No tech doc, no planning pass. If the cause is not obvious, rule out engine quirks before project code.

**Deliverable.** A fix plus a test that mirrors the repro.

**Done when.** The repro stops producing the symptom in a real game session.

**Smell that this is the wrong flow.** If the "fix" turns out to need cross-system architecture, stop and escalate. The work is no longer a bug; it's a feature or a refactor.

## Spike

A question that can't be answered without exploring code, prototyping, or research.

**Entry.** The question, time-boxed. "Is the AI prediction good enough for two balls?" is a spike. "Can we use Godot 4.5's new audio bus features?" is a spike. "Walk the new contributor onboarding cold and see where it breaks" is a spike.

**Shape.** A scratchpad writeup by default (promoted to [the research folder](../research/) only when the work earns it) and often a throwaway prototype branch. The prototype is for evidence, not for merging.

**Deliverable.** **Feature issues filed in Linear.** The writeup is a vehicle; the tickets are what carries the value forward. A spike that ends without feature issues is unfinished, the question got answered, but nothing acts on the answer.

**Done when.** Linear has the tickets the spike's findings unlocked.

**Smell that this is the wrong flow.** If the question is small enough to answer with a single grep or a quick read, just answer it inline. If the prototype is going to ship, promote it to a feature and start that flow.

## Feature

A player-facing capability or a refactor whose blast radius crosses multiple files or systems.

**Entry.** The player-facing outcome the player should see when it's done.

**Shape.** Four phases:

1. **Frame.** Name the player-visible outcome.
2. **Design pass.** The end state goes on the page for the thing it changes, fiction first, then design, then how it is built. A decision with options worth recording gets a spike. Decisions land in the doc, not in chat.
3. **Plan.** A sequenced plan with blast-radius analysis, scoped per PR. Open design calls surface for Josh to decide, then fold back into the plan.
4. **Build.** Each plan step lands as its own challenge, stacked when steps depend on each other. Every challenge ships as a draft, runs static checks and GUT, and is reviewed before it merges. When the stack is ready, it folds into the parent feature branch; Josh validates player-feel at runtime.

**Deliverable.** The capability shipped end-to-end, the tech doc reflecting the landed system, sub-tickets closed, playtest passed.

**Done when.** The player can use the capability in real gameplay. The playtest confirms feel, not just function.

**Smell that this is the wrong flow.** If the work is single-file with a clear repro, drop the design overhead, it's a bug. If the work is "we don't know how X should work," the output should be tickets, not code, it's a spike.

## Reporting discipline (cross-flow)

Every progress report opens with the player-visible status, not the architectural deliverable. "Foundations 3/6 complete; bug not yet visible-fixed" is the right shape until the load-bearing step lands. "Stack landed" is not a status; the status is whether the player can still hit the bug.

## Choosing the flow

- One-file fix with a clear repro → **bug**.
- "We don't know how X should work" / "is Y feasible?" → **spike**.
- "Build / refactor X across files" with a known target shape → **feature**.

## Cascades

Flows feed each other. Each handoff is a flow boundary; pick the new flow's shape, not the old one's.

- A spike's tickets launch a feature.
- A feature spawns bug-fix follow-ups.
- A bug fix reveals an architectural smell that becomes a spike, which becomes a feature.

The handoff is the natural break point. Don't carry a half-baked spike into feature work without filing the tickets; don't carry a single-file bug into feature work without checking whether the bug is the whole job.
