# Refactor as you go

When a change brings you up against debt, a legacy shape, or a corner that wants reshaping, reshape it in the same PR. The PR that touched the rough spot is the one that cleans it.

Volley is early enough that "merge first, refactor later" piles up faster than it ever gets paid down. So the habit we lean on is the opposite: leave the code a little better than you found it, right there in the change that found it.

## What this covers

The reshaping you do alongside your change:

- Quality the PR is sitting on top of: a rename smell, dead code, logic duplicated in two places.
- Doc-structure moves, when the change shifts where something lives.
- Pulling config out to its proper home as you touch the feature that uses it.
- Going straight to the right shape instead of leaving a shim or a forwarding layer behind.
- Deleting a deprecated path once the new one is live.

The thread through all of these: the work is adjacent to what you came to do, and finishing it leaves the area cleaner than a follow-up ticket ever would.

## What this does not cover

Two things stay out of the PR.

Pre-existing debt your change does not touch belongs in a ticket, not folded into unrelated work. A tight PR that does one thing lands faster and reads better later.

A genuinely large cleanup that would balloon the change is worth surfacing rather than either swallowing into the PR or splitting off on your own. Flag it in the thread and let the maintainer help decide where it goes.

## Two ways debt gets paid down

The point of refactoring as you go is that debt does not sit as a backlog lump that quietly rots. It gets paid down two ways.

**Incrementally.** Bit by bit, cycle by cycle, as changes pass through the areas that need it. Most debt clears this way without anyone scheduling it.

**By prefactor.** When a feature is about to touch an area that would be much nicer to build on once cleared, do the refactor first, as the feature's enabling step. A filed debt or architecture ticket is exactly the prefactor candidate for the next feature that reaches into that area: clear it, then build on the better ground.
