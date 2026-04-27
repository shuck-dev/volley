# Ball Speed Tiers and Physics Ceiling

Spike SH-88. Defines a world max ball speed the 2D physics can reliably handle, the tier math on top of it, and how ball-speed items interact with the tier stack instead of raising a single linear cap.

Companion design doc: [20a Ball Speed Tier Progression](20a-ball-speed-tier-progression.md) covers the narrative framing and the reward ladder that sits on top of this ceiling.

## Goal

Current speed model is linear: `ball_speed_min` base, `ball_speed_increment` per hit, clamped to `ball_speed_min + ball_speed_max_range`. Miss resets to min. Items like Court Lines raise `ball_speed_max_range` additively, Cadence raises it further on `on_max_speed_reached`, Wrist Brace raises `ball_speed_increment`. With enough stacking, long rallies push the ball arbitrarily fast and the ceiling becomes a soft curiosity rather than a goal.

What this spike owns:

1. A hard speed the physics pipeline can promise to handle on a 60 Hz tick.
2. Tier math that fits inside that ceiling and gives items somewhere to stack without sliding it sideways.
3. A rewrite of the speed-shaping items against the tier ladder.

The companion doc (20a) owns the narrative framing of the tiers, what each peak rewards, and the felt experience of climbing.

## The physics ceiling

Godot's 2D physics in this project runs at the engine default 60 ticks per second. At discrete-step integration the ball can tunnel through thin colliders if per-frame travel exceeds the contact depth of what it is trying to hit. The three failure modes, in order of how quickly they bite, are: paddle face (closing speed of ball + paddle has to stay under the paddle's hit-axis thickness plus ball radius), paddle edge on a shrunk paddle, and walls.

The spike exposes a single constant, `BALL_WORLD_MAX_SPEED`, which is the world max speed the physics pipeline can reliably handle at 60 Hz against the narrowest paddle and thinnest wall in the scene. Its value is tuned during prototyping against the actual collider dimensions and paddle-speed curve, not baked into the architecture.

**No stacked item, no effect outcome, no debug cheat may push `ball.speed` above `BALL_WORLD_MAX_SPEED`.** This is a physics guarantee, not a balance number.

### Continuous collision detection as a pressure valve

If the speed ceiling turns out too tight under real play, Godot's [`RigidBody2D.continuous_cd`](https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html#class-rigidbody2d-property-continuous-cd) is the pressure valve: enabling it resolves contacts along the swept path rather than at tick boundaries, trading physics-thread cost for headroom above the discrete-step ceiling. The specific mode and the tiers it turns on at are prototype-time decisions, not an architectural commitment.

## Tier math

Ball speed is friendship energy. The rally's accumulated speed is the player's relationship with the ball, and the tier ladder is the shape of that energy as it climbs. Speed resets only on miss; mid-rally grab-and-release carries energy through the held-token detour (see `21-ball-dynamics.md` for the regime model). Tiers compose with that semantics: a grab-and-release at Tier 2 lands at Tier 2, and misses are the only thing that takes the rally back to Tier 0.

Speed progression becomes a ladder of tiers. Each tier has its own floor and ceiling; reaching a ceiling fires a tier event and drops the ball to the floor of the next tier. The reward that fires alongside the event is owned by the companion progression doc.

### Tier structure

The ladder has three or four tiers (final count is a design call made in the prototype). Tier 0 is the base rally speed; each subsequent tier steps up to a progressively higher band, with the ceiling raised by that tier's `ball_speed_max_range` entry. The top tier's ceiling is the world max speed the physics can reliably handle, tuned during prototyping. Tier 0's floor and width match today's base-stats numbers, so starting a run feels the same as today.

No tier, no item, no effect can promote the ball past the top tier's ceiling.

### Tier-completion event

Reaching a tier ceiling fires `on_tier_completed(tier_index)` on the item effect bus, drops `ball.speed` back to the new tier's floor, and continues the rally. The event payload carries the completed tier index so effect outcomes and reward handlers can scale their response. Completing the top tier additionally opens a Peak window; see 20a for its framing and reward payload.

### Reset behaviour

- **Miss** resets tier to 0 and speed to Tier 0 floor, matching today's `ball.reset_speed` semantics.
- **Tier completion** sets tier to `tier + 1` and speed to the new tier's floor. Current speed does not carry across tiers; the drop is the reset beat.
- **Peak window end without miss** drops speed and tier to 0 but does not count as a miss. The rally continues. Call this the "cooldown" reset: no penalty events fire, `_volley_count` is preserved, the Court just feels the speed drop.
- **Peak window end by miss** behaves as a normal miss: tier 0, volley count 0 (or halved if a halve-streak item is active, same as today).
- **Half-streak items** (Cadence's existing `on_miss` / halve outcome) still halve `_volley_count` on miss. They now also set tier to `floor(current_tier / 2)` and speed to the floor of that tier, so halving is proportional across the new ladder.

### Tier-aware ball state

`Ball` gains `current_tier: int` and `tier_floor` / `tier_ceiling` derived from `current_tier` against a `SpeedTierTable` resource. Each tier entry in the table carries `{ floor, ceiling, max_range, reward }`, where `max_range` is the per-tier promotion of the flat `ball_speed_max_range` stat from 21-ball-dynamics.md. Tier 0's `max_range` holds the existing flat value from 21's base-stats tuning surface, so that surface keeps its meaning and lives on the Tier 0 entry. `increase_speed` and `set_speed_for_streak` clamp against `tier_ceiling` instead of `max_speed`. Crossing `tier_ceiling` triggers `_advance_tier` which emits `tier_advanced(new_tier)` and `on_tier_completed` through `ItemManager.process_event`.

`speed_changed` grows to carry tier floor and ceiling instead of global min and max, so the speed bar can render the current band. `at_max_speed_changed` is repurposed to fire only on Peak entry/exit; the Cadence "ceiling outcome" (which currently latches on `on_max_speed_reached`) moves to `on_tier_completed` with a tier filter.

## Items under the tier model

The four items that currently shape ball speed keep their fantasy. Each stops trying to slide a single linear ceiling and starts interacting with the tier stack.

### Cadence

Current: oscillates `ball_speed_offset` within `ball_speed_max_range`; on `on_max_speed_reached` raises `ball_speed_max_range`.

New: oscillation stays (it is a feel effect, not a ceiling effect). The ceiling-raising outcome becomes a **tier-skip chance** on `on_tier_completed`: a per-level chance to skip the next tier's climb and drop straight into the tier after. "Don't stop. Won't stop" reads as "keep the tempo, skip the queue," and the item keeps rewarding long rallies without raising the absolute cap.

### Court Lines

Current: flat per-level addition to `ball_speed_max_range`.

New: **widens tiers** without raising their ceilings. Each level lifts the floors of the tiers above Tier 0 by a small amount, so bands start higher but still end at the same fixed ceilings and climbs take fewer hits. The flavour ("the ceiling keeps moving") shifts to "the start line keeps moving", which reads cleaner.

### Training Ball

Current: flat per-level addition to `ball_speed_min`.

New: unchanged in shape. Training Ball raises Tier 0 floor only; it does not affect higher tiers. Base serves come in faster and Tier 0 finishes quicker, but the item stops colliding with the tier structure above. "Already moving" still fits.

### Wrist Brace

Current: per-level addition to `ball_speed_increment`, with a `paddle_size` percentage penalty.

New: unchanged. Wrist Brace compresses every tier's hits-to-climb and trades paddle size for ramp speed. It is the "do the climb faster" item; layering it under a tier model is exactly what we want.

### Interactions at the extremes

- Full speed stack (Court Lines + Training Ball + Wrist Brace at cap): Tier 0 starts higher, climbs compress, top-tier ceiling holds. Peak becomes reachable inside a short rally. This is the new power fantasy. Without tiers, the same stack today sends speed arbitrarily high and breaks the paddle.
- Cadence with any speed stack: tier-skip chance shrinks the average Peak-to-Peak interval, which is the Cadence identity under this model.
- Training Ball alone: Tier 0 compression only. Stops interacting with the tier ladder above Tier 0, which is what "early-game smoothing" items should do.

## Migration notes

- `ball_speed_max_range` stays as a tuning surface; it is promoted into a per-tier `max_range` field on `SpeedTierTable` rather than deleted. The flat value from 21-ball-dynamics.md rides on the Tier 0 entry so existing tuning and tests keep their meaning; the tiers above each declare their own `max_range` alongside `floor`, `ceiling`, and `reward`. The table is owned by `GameRules`. Existing callers that read `ball_speed_max_range` read `SpeedTierTable.get_tier(current_tier).max_range` (or `.get_tier(0).max_range` for the base-stats tuning surface).
- Cadence's `on_max_speed_reached` outcome is rewritten to `on_tier_completed` with a tier filter. Court Lines' `ball_speed_max_range` stat outcome is rewritten to a new `widen_tier_floors` outcome. Training Ball and Wrist Brace unchanged.
- Court's `_on_ball_at_max_speed_changed` splits into `_on_ball_tier_advanced` (fires per tier) and `_on_ball_peak_changed` (fires on Peak entry/exit). `on_max_speed_reached` as an event name is retired; `on_tier_completed` replaces it.
- `ball.reset_speed` stays as miss behaviour. `ball.advance_tier` is new. `ball.set_speed_for_streak` clamps against `tier_ceiling` of the tier implied by streak count, which the tier table answers.
- No save compat shim. Items in flight at migration time reload against the new data and pick up the new behaviour.

## Open questions

- CCD per-body cost on the web export, if we need to reach for it. Needs a frame-budget measurement in the prototype before committing to CCD as the way past the discrete-step ceiling.
- Do Partners care about tier? Martha's current numbers do not touch speed, but a future Partner could want an `on_peak_hit` outcome. The event bus should accept it without special casing.

## Acceptance criteria mapping

- Hard physics ceiling identified and named. `BALL_WORLD_MAX_SPEED` exists as the single constant the pipeline guarantees, tuned in the prototype against the 60 Hz tick, paddle collider width, and min paddle size.
- CCD evaluated as a pressure valve available if the ceiling proves too tight in play.
- Tier progression designed. Three or four tiers; hits-per-climb falls out of base increment and per-tier `max_range`.
- Reset behaviour defined. Miss to Tier 0 floor. Tier completion to next tier floor. Peak end without miss drops to Tier 0 floor without counting as a miss.
- Existing-item interactions documented. Cadence, Court Lines, Training Ball, Wrist Brace all re-expressed against the tier stack.
- Narrative framing and reward ladder live in [20a Ball Speed Tier Progression](20a-ball-speed-tier-progression.md).
