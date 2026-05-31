# Ball Speed Tier Progression

Design companion to SH-88. Where [20 Ball Speed Tiers and Physics Ceiling](20-ball-speed-tiers.md) owns the physics ceiling, tier math, and item stat interactions, this doc owns the game-design side: why tiers exist at all, what the player earns when they reach the top of one, and what a tier climb feels like from inside a rally.

## Why tiers exist

A linear speed ramp without internal structure gives the player no landmarks. The ball gets faster, the number on a bar goes up, and nothing along the way acknowledges the work the rally is doing. Tiers break the ramp into distinct beats so the climb has shape (three tiers to start, tunable). Each tier is a short stretch of rally with a recognisable entry speed, a peak, and a handover to the next tier. On the current court the bands are tight (about ten hits a tier); a wider court raises the speed ceiling and lets the climbs run longer.

Reaching the top of a tier is supposed to register as an event, not as a number crossing a threshold. The consolidation event and the multiplier it raises (below) are the mechanism that registers it.

## Soul, the multiplier, and consolidation

Soul (the same resource as friendship points) is earned per paddle hit. The amount is `base x multiplier`, where base is 1 and the multiplier is what the climb grows.

- **Base soul per hit is 1.** Every hit banks one soul before the multiplier.
- **The multiplier starts at x1 and rises +1 each consolidation.** So a fresh rally pays 1 soul per hit; after one consolidation, 2 per hit; after two, 3; and so on. The deeper the rally climbs, the more every remaining hit is worth.
- **A miss resets the multiplier to x1.** The rally's climb is its own; the next rally starts over. This is the loop's risk: a long climb abandoned is a long climb to rebuild.

Consolidating is the whole mechanic. It is not a lump reward banked at a tier top; it is the act that raises the multiplier, which makes the rest of the rally pay more. The reward for reaching the top of a tier is that every subsequent hit is worth more, not a one-off coin.

## Consolidation is an event

A consolidation fires an event into the item-effect system (a trigger type, e.g. `on_consolidation`), the same machinery items already hook for `on_miss`, `on_max_speed_reached`, and the rest. The built-in effect of the event is `+1 multiplier`; items and partners subscribe to the same trigger to add their own consolidation effects without special-casing.

Peak is a consolidation event too, not a separate reward shape. Entering Peak carries the default `+1 multiplier` like any consolidation, and additionally opens the increased speed range above the ball's own max where the rally keeps climbing hit by hit. So Peak is the top consolidation: the same +1 the climb has been paying, plus the wider band. Items can hook the Peak event for anything richer.

## UI (temporary)

The current UI is scaffolding, replaced when the art and UI pass lands. Two surfaces read the mechanic for now:

- A floating `+N` over the ball on each hit, where N is the soul that hit earned (the current multiplier).
- A standing multiplier readout (x2, x3, ...) that climbs with each consolidation and reads x1 at the base.

These are dev-legibility aids, not the shipped feel. The shipped tone target stays as below.

Tone target (shipped, later pass): no banners, no permanent floating text, no venue-rule violations. The felt reward is a sound, a light, a trail, a coin, or an unlock signal at the next shop. Quiet and diegetic. The temporary floats and readouts above are explicitly placeholder against that target.

## What a tier climb feels like

A single tier climb is a sustained stretch of rally. The speed bar fills inside its current band, the audio wash climbs, and the paddle starts to feel like it matters a little more on each return. At the top of the band the consolidation fires: the multiplier ticks up, so every following hit pays more, the band resets to the next tier's floor, and the climb starts again from a new base. Completing the top tier opens the Peak: the same multiplier tick plus an extra range above the ball's own max where the ball keeps climbing hit by hit toward the world's hardest speed. The Peak holds while the rally lives and ends on a miss.

Across a full run the player's felt arc is: Tier 0 is the warm-up, Tier 1 is the acknowledgement, the top tier is the commitment, and Peak is the moment it lands. Missing anywhere in that arc drops the multiplier back to x1; the next rally starts the climb over, which is a feature of the loop. The work of the run is sustaining a high multiplier deep into a rally, where each hit pays the most, and the soul banked across the run is what the shop loop spends.

## Open questions

- Peak-miss penalty. A "crash" that drops more than the multiplier (e.g. a soul forfeit) would give Peak risk. Start without it; revisit once the multiplier has playtest data.
- Tier 0 consolidation. Whether the first consolidation pays its +1 like the rest, or the warm-up tier is excluded so the multiplier only starts climbing from Tier 1. Start with every consolidation paying +1; revisit if the early climb feels flat.
- Multiplier display ceiling. Whether a very high multiplier needs a cap or a different readout; out of scope until playtest shows rallies running that long.
- Tier count and band widths. Three to start; whether the climbs want to run longer is a court-width question (a wider court raises the ceiling and stretches the bands) more than a tier-count one.
