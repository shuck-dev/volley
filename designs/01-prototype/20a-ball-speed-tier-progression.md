# Ball Speed Tier Progression

Design companion to SH-88. Where [20 Ball Speed Tiers and Physics Ceiling](20-ball-speed-tiers.md) owns the physics ceiling, tier math, and item stat interactions, this doc owns the game-design side: why tiers exist at all, what the player earns when they reach the top of one, and what a tier climb feels like from inside a rally.

## Why tiers exist

A linear speed ramp without internal structure gives the player no landmarks. The ball gets faster, the number on a bar goes up, and nothing along the way acknowledges the work the rally is doing. Tiers break the ramp into distinct beats so the climb has shape (three tiers to start, tunable). Each tier is a short stretch of rally with a recognisable entry speed, a peak, and a handover to the next tier. On the current court the bands are tight (about ten hits a tier); a wider court raises the speed ceiling and lets the climbs run longer.

Reaching the top of a tier is supposed to register as an event, not as a number crossing a threshold. The companion reward ladder below is the mechanism that registers it.

## Reward ladder

Rewards are what fires on `on_tier_completed`. They are tuned for first playtest, not for shipped balance. The ladder reads off the tier table, so it stretches or shrinks with the tier count; below is the three-tier starting shape, where the top tier is Tier 2 and the Peak opens above it.

- **Tier 0 peak** (entering Tier 1). Baseline rally state. No reward fires. The band shift is its own felt beat: the ball arrives in the next register, audio brightens a step, the trail gets a little longer. The rally counter ticks in its normal rhythm.
- **Tier 1 peak** (entering Tier 2). A bigger audio beat and a sparkle off the ball at the moment of the transition. One friendship tick lands on the next paddle hit, and the rally counter flourishes a single beat bigger than its usual tick. A brief aura reads through the next few hits.
- **Top-tier peak** (Peak window opens). The rare, shop-tier beat. The aura holds for the full Peak window, paddle hits inside Peak play a richer return sound, and the window banks a mid-sized currency drop that the player feels in the next shop. Only one Peak reward banks per rally. A shop voucher and an item-unlock signal are viable alternatives for a later pass; they become extra `on_tier_completed` reward handlers without replacing the currency drop.

All rewards are opt-in for items; an item effect bound to `on_tier_completed` with a tier filter can add to these without replacing them. Partners can hook `on_peak_hit` (emitted per paddle hit while Peak is open) to add their own beats without any special casing.

Tone constraints: no banners, no floating text, no venue-rule violations. Rewards are a sound, a light, a trail, a coin, or an unlock signal the player will see next time they visit the shop. Quiet and diegetic.

## What a tier climb feels like

A single tier climb is a sustained stretch of rally. The speed bar fills inside its current band, the audio wash climbs, and the paddle starts to feel like it matters a little more on each return. At the top of the band the tier reward fires (see ladder above), the band resets to the next tier's floor, and the climb starts again from a new base. Completing the top tier opens the Peak: an extra range above the ball's own max where the ball keeps climbing hit by hit toward the world's hardest speed. The Peak holds while the rally lives and ends on a miss.

Across a full run the player's felt arc is: Tier 0 is the warm-up, Tier 1 is the acknowledgement, the top tier is the commitment, and Peak is the moment it lands. Missing anywhere in that arc drops back to Tier 0; the next rally starts the climb over, which is a feature of the loop. The work of the run is producing Peak windows, and the shop loop is where Peak rewards get spent.

## Open questions

- Peak-miss penalty. A "crash" that halves this rally's coin take would give Peak risk. Start without it; revisit once the reward ladder has playtest data.
- Tier 0 peak is currently rewardless. If playtest shows Tier 1 entry feels abrupt, a very small fiction-only beat (a single sparkle, no friendship, no coin) can fill the gap without changing the ladder's economy.
- Tier count and band widths. Three to start; whether the climbs want to run longer is a court-width question (a wider court raises the ceiling and stretches the bands) more than a tier-count one.
