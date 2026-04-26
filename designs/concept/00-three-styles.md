# The Three Styles

The high-level architecture of Volley as a game. This doc carries the shape and how the three styles relate; per-arc docs in this folder carry the detail.

This is a working set of docs. Refinement passes follow.

## Map

- This doc: the game's overall shape and how the three styles fit together.
- `01-construction.md`: Part 1. The vibrant world, the tournament, the cast, the rally, the count.
- `02-cracks-and-break.md`: cracks across Part 1, the championship win that lands wrong, the involuntary walk through the hometown.
- `03-reconstruction.md`: Part 2. Dread, the photo album, the sister, the unnamed number, the search.
- `04-reality.md`: Reality as a style. Visuals, audio, the structural shape of a Reality scene.
- `05-postgame.md`: the cliff, the call, the credits, the postgame rally.

## Two worlds, one game

Volley holds two worlds. The player meets the first as the world. The second arrives later and is the one that was always there.

**Construction** is the vibrant one. A garden in late afternoon, a stall against the inside wall, a racquet on the left, a friend at the counter watching the rally, glad to be there. Saturated colour, generous light. Tennis lives here and only here. The protagonist built it and keeps it tending. The pretense is the rendering, not the protagonist's care.

**Reality** is the protagonist's actual hometown. A small coastal town on the Welsh and Cornish coast in an imagined warmer climate: painted terraces in seaside colours, whitewashed walls, palm trees in places, Mediterranean light on a British coastline. The same people live here at their actual ages. One of them, the friend from the stall, has been pushed away. Reality is gold-hour, weighted, plainer.

The player learns Construction is a construct only as the climb cracks open. The garden the player has been rallying in is the protagonist's memory of their actual garden in Reality, sprucing it up. Constructed garden and real garden remain separate places.

## The garden is the meeting point

The garden is the one venue where Construction and Reality overlap. Other Construction venues are purely fantastic, with no Reality counterpart. The garden's out-of-place-out-of-time feel comes from being the one venue grounded in the real hometown.

The title carries the weight. Literal place. Tended thing. Where things grow: rally, obsession, memory. Pre-Fall innocence preserved. Walled enclosure.

## One locked gate

There is one locked gate in the whole game. In the garden. Walking through it transitions to Reality. The cliff is on the other side. The gate opens once, late, when the sister hands over the key.

## The two-act spine

Volley is shaped in two acts.

**Part 1 is Construction.** The protagonist climbs the volley world ladder. Each main venue hosts one round; coach-partners train them in mechanics that compose into the kit; the championship sits at the top. The stated goal is the world record. The cracks accumulate. The win arrives. The win lands wrong.

**Part 2 is Reconstruction.** The construct cannot hold itself together once its central goal has been achieved and proved meaningless. The shopkeeper is missing. The protagonist searches Reality for traces of where they went, fearing the worst, while the player carries a phone with the unnamed number that never connects. The album fills, a key falls out, the gate opens, the cliff is on the other side.

The two acts use the two styles in different proportion. Part 1 is mostly Construction, with Reality leaking in through cracks. Part 2 lives in both, with Reality carrying the search and Construction holding the rally that surfaces what the protagonist is searching for.

## Cross-style principles

These bind the styles together. The per-arc docs do not contradict them.

**Everyone is real.** The supporting cast in Construction is the real cast from the protagonist's life, rendered young, vibrant, present. The same people exist in Reality at their actual ages. Two asset sets per cross-style character. The exception is the champ: Construction-only, the dead friend rendered as the championship final, no Reality counterpart.

**The hook is in dialogue, not HUD.** The world record is named by a character in the first session. The number is on a HUD; the meaning is not.

**Cracks are tonal and meta-contextual, never concrete.** A real-world object literally appearing inside Construction reads as a flag the player can point at. A flicker in the venue light, a music cue that skips, a UI element that blinks the wrong colour, a loading screen that says something it should not: these are easier to absorb and harder to name. Concrete leakage breaks the deniability the cumulative shape needs.

**The unnamed number is load-bearing across both acts.** The shopkeeper's number sits in the protagonist's phone, unnamed. The player has full control of the phone throughout Construction, Reconstruction, and the cliff. Dialling never connects until the final beat. The unanswered ring is the player-facing weight of the protagonist's reach without contact.

**Reality is finite hand-crafted content.** The hometown is built once with iterative additions across Part 2. Reality cannot be procedural; the team builds each scene.

**The period is pre-smartphone.** Late 90s or early 2000s as a tonal range. Phones flip or candy-bar or land-line. Numbers held in heads or written on paper. The unnamed-number mechanic depends on the period.

## What this teaches each surface

The artist world bible holds the visual canon and the cast. The concept docs hold the structural spine. The character docs hold interior life. The audio direction (SH-281) holds the music arc. SH-279 holds the Reality gameplay tooling.

Each cross-style character has two asset sets. The champ is the exception. Cracks are tonal and atmospheric; concrete reality-leaks are out. Reality is hand-crafted scene content, gated by photos. The photo album and the unnamed number are the load-bearing mechanics of Part 2.

## What this teaches the production

Construction's content scales: procedural rally, item economy, partner system, tournament rounds. Reality's content does not: the hometown is built once with iterative additions; the cliff is a separate location built once.

Idle pacing means the cracks need to escalate slowly enough that month-long players read them as cumulative rather than clustered around early sessions.

The cast doubles in Part 2 (each cross-style character with a Reality-side asset). Worth bounding the partner count early.

## Prototype scope

Per SH-275, the prototype delivers Part 1's first venue: the garden. Martha as the coach, one mechanic she teaches, one round match. Part 2 and the cliff are post-prototype.

## Open questions (synthesis index)

The questions live in the per-arc docs; this is the index.

From `01-construction.md`: the encounter shape per round. Partner unlock cadence. Mechanic-per-coach specifics. Round-match win condition.

From `02-cracks-and-break.md`: crack pacing across idle play. Tonal-vs-meta crack mix. How the cracks behave during the championship attempt itself.

From `03-reconstruction.md`: photo count across Part 2. Per-photo scene shape. Cliff-trigger gate. Bridge unlock signal after the break.

From `04-reality.md`: per-scene state persistence. The interaction surface vocabulary. How dialogue layers across return visits.

From `05-postgame.md`: what Construction looks like in postgame with the championship spot occupied by the shopkeeper. Whether the cliff becomes a returnable place after the call.
