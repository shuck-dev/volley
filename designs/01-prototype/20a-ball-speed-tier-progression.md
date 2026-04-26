# Ball Speed Tier Progression

Design companion to SH-88. Where [20 Ball Speed Tiers and Physics Ceiling](20-ball-speed-tiers.md) owns the physics ceiling, tier math, and item stat interactions, this doc owns the game-design side: why tiers exist at all, what the player earns when they reach the top of one, and what a tier climb feels like from inside a rally.

## Why tiers exist

A linear speed ramp without internal structure gives the player no landmarks. The ball gets faster, the number on a bar goes up, and nothing along the way acknowledges the work the rally is doing. Tiers break the ramp into four distinct beats so the climb has shape. Each tier is a short stretch of rally, ~18-20 well-placed hits, with a recognisable entry speed, a peak, and a handover to the next tier.

Reaching the top of a tier is supposed to register as an event, not as a number crossing a threshold. The companion reward ladder below is the mechanism that registers it.

## Narrative framing

Volley!'s rally fiction lives in the "spirit of the volley" framing from [08 Court Bounds](08-court-bounds.md). A rally is tribute; the spirit answers sustained commitment and lifts the ball while it does. Tiers are how that answer gets louder. Tier 0 is the spirit arriving. Tier 1 is the spirit noticing. Tier 2 is the spirit leaning in. Tier 3 is the spirit fully present, and Peak is the brief window where it is saturating the exchange.

The fiction keeps the rewards diegetic. Tier payoffs are gestures the spirit makes in answer to the rally, not a banner announcing a milestone. The venue rule still holds: nothing pops onto the screen to read, everything is expressed in the court.

Reset, framed in the fiction: a miss sends the spirit away and drops the ball to Tier 0 floor. Tier completion is the spirit settling into a new register and the ball eases into the next band. Peak end without a miss is the spirit receding on its own once its window is spent, and the rally continues on quieter terms.

## Reward ladder

Rewards are what fires on `on_tier_completed`. They are tuned for first playtest, not for final balance.

- **Tier 0 peak** (entering Tier 1). Baseline rally state. No reward fires. The band shift is its own felt beat: the ball arrives in the next register, audio brightens a step, the trail gets a little longer. The rally counter ticks in its normal rhythm.
- **Tier 1 peak** (entering Tier 2). Small cheer and a sparkle off the ball at the moment of the transition. One FP tick lands on the next paddle hit. The rally counter flourishes, a single beat bigger than its usual tick. No currency, no unlock; the spirit has just noticed.
- **Tier 2 peak** (entering Tier 3). A bigger audio beat on the transition and a brief aura around the ball that reads through the next few hits. A small currency reward drops as a diegetic shard or coin that arcs into the HUD counter (no banner). The spirit is leaning in.
- **Tier 3 peak** (Peak window opens). The rare, shop-tier beat. The aura holds for the full Peak window, paddle hits inside Peak play a richer return sound, and the window closes with a banked reward: a shop voucher, an item unlock signal, or a mid-sized currency drop that the player feels in the next shop. Only one Peak reward banks per rally.

All four rewards are opt-in for items; an item effect bound to `on_tier_completed` with a tier filter can add to these without replacing them. Partners can hook `on_peak_hit` (emitted per paddle hit while Peak is open) to add their own beats without any special casing.

Tone constraints: no banners, no floating text, no venue-rule violations. Rewards are a sound, a light, a trail, a coin, or an unlock signal the player will see next time they visit the shop. Quiet and diegetic.

## What a tier climb feels like

A single tier climb is a minute-ish of sustained rally. The speed bar fills inside its current band, the audio wash climbs, and the paddle starts to feel like it matters a little more on each return. At the top of the band the spirit's answer fires (see ladder above), the band resets to the next tier's floor, and the climb starts again from a new base.

Across a full run the player's felt arc is: Tier 0 is the warm-up, Tier 1 is the acknowledgement, Tier 2 is the commitment, Tier 3 is the conversation, and Peak is the moment the conversation lands. Missing anywhere in that arc drops back to Tier 0 and the spirit retreats; the next rally starts the climb over, which is a feature, not a punishment. The work of the run is producing Peak windows, and the shop loop is where Peak rewards get spent.

## Open questions

- Shop-tier reward shape at Tier 3. A voucher (choose next shop slot), an unlock token (advance a partner track), and a banked-currency drop are all viable. Pick one for first playtest; the others become event-bus reward handlers later.
- Peak-miss penalty. A "crash" that halves this rally's coin take would give Peak risk. Start without it; revisit once the reward ladder has playtest data.
- Tier 0 peak is currently rewardless. If playtest shows Tier 1 entry feels abrupt, a very small fiction-only beat (a single sparkle, no FP, no coin) can fill the gap without changing the ladder's economy.
