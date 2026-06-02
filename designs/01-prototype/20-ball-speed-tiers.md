# Ball Speed Tiers and Physics Ceiling

Spike SH-88. Defines a world max ball speed the 2D physics can reliably handle, the tier math on top of it, and how ball-speed items interact with the tier stack instead of raising a single linear cap.

Companion design doc: [20a Ball Speed Tier Progression](20a-ball-speed-tier-progression.md) covers the narrative framing and the reward ladder that sits on top of this ceiling.

## Goal

Current speed model is linear: `ball_speed_min` base, `ball_speed_increment` per hit, clamped to `ball_speed_min + ball_speed_max_range`. Miss resets to min. Items like Court Lines raise `ball_speed_max_range` additively, Cadence raises it further on `on_max_speed_reached`, Wrist Brace raises `ball_speed_increment`. With enough stacking, long rallies push the ball arbitrarily fast and the ceiling becomes a soft curiosity rather than a goal.

What this spike owns:

1. A hard speed the physics pipeline can promise to handle on a 60 Hz tick.
2. Tier math that fits inside that ceiling and gives items somewhere to stack without sliding it sideways.
3. A rewrite of the speed-shaping items against the tier ladder.

The companion doc (20a) owns the narrative framing of the tiers, what each tier completion rewards, and the felt experience of climbing.

## The physics ceiling

Godot's 2D physics in this project runs at the engine default 60 ticks per second. At discrete-step integration the ball can tunnel through thin colliders if per-frame travel exceeds the contact depth of what it is trying to hit. The three failure modes, in order of how quickly they bite, are: paddle face (closing speed of ball + paddle has to stay under the paddle's hit-axis thickness plus ball radius), paddle edge on a shrunk paddle, and walls.

The world exposes a single value, `BALL_WORLD_MAX_SPEED`, the top speed any ball reaches. Two constraints bound it, and the lower one wins:

- **Fun.** A crossing must outlast the receiver's move plus reaction, or the point is luck rather than skill. On the current court (600px paddle to paddle, miss-zone reach about 330px, paddle travel 560px/s) the fair-crossing floor is roughly 0.8s, which puts the fun ceiling near 750px/s. Past that the ball outruns a human across the court. This ceiling scales with crossing distance, so it derives from court width (see [Court width](#court-width)), not a fixed number.
- **Physics.** At 60Hz a discrete-step body tunnels through a collider once per-tick travel exceeds the collider's contact depth plus the ball diameter. This sets a hard floor under the fun ceiling. It is not fixed by the art: a paddle's collision face can be authored thicker than its sprite, which raises the tunnelling ceiling with no visible change (at a small phantom-bounce cost on shrunk paddles). So the collider face is a dial, sized to keep whatever the fun ceiling asks for tunnel-safe.

First-pass value: `BALL_WORLD_MAX_SPEED = 720` at the default court width. At 720 the ball travels 12px/tick, already inside the thinnest current paddle face (14.4) plus ball diameter (14.4), so no collider thickening is needed yet; it is the lever for a wider court or higher ceiling later.

**No stacked item, no effect outcome, no debug cheat may push `ball.speed` above `BALL_WORLD_MAX_SPEED`.** This is a physics guarantee, not a balance number.

### The physics tick is the other dial

The tunnelling budget is `depth * tick_rate`, so the tick is a linear multiplier on the physics floor: doubling it doubles the speed the pipeline can carry, with none of the phantom-bounce cost the collider-face dial has. The project runs at the engine default 60 ticks per second; this game's per-tick cost is small (a 2D ball, two paddles, an effect processor, and a handful of cheap controllers), so raising the tick is cheap here in a way it would not be for a many-body sim. The catch is feel: speeds and timings tuned against 60Hz (the relock ramp, AI cadence, the english coefficient sampled from per-tick paddle velocity) want re-tuning once after the change. Because that re-tune is one-time and the prototype is already tuning the ladder, the tick is best raised before the tier numbers settle rather than after. Raising it to 120 doubles the headroom and aligns with common high-refresh displays; past that the fun ceiling caps speed well before the physics floor does, so there is little reason to go higher. Tracked separately as its own ticket.

### Continuous collision detection as a pressure valve

If the speed ceiling turns out too tight under real play, Godot's [`RigidBody2D.continuous_cd`](https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html#class-rigidbody2d-property-continuous-cd) is the pressure valve: enabling it resolves contacts along the swept path rather than at tick boundaries, trading physics-thread cost for headroom above the discrete-step ceiling. The specific mode and the tiers it turns on at are prototype-time decisions, not an architectural commitment.

## Tier math

Rally speed accumulates across paddle hits and persists through mid-rally grab-and-release (see `design/21-ball-dynamics.md` for the regime model). Speed resets only on miss. Tiers compose with that: a grab-and-release at Tier 2 lands at Tier 2, and misses are the only thing that takes the rally back to Tier 0.

Speed progression becomes a ladder of tiers. Each tier has its own floor and ceiling; reaching a ceiling fires a tier event and drops the ball to the floor of the next tier. The reward that fires alongside the event is owned by the companion progression doc.

### Tier structure

The ladder has three tiers (tunable; the table is data, so the count can change). Tier 0 is the base rally speed; each subsequent tier steps up to a progressively higher band, with the ceiling raised by that tier's `ball_speed_max_range` entry. The top tier's ceiling is the ball's own max speed, which depends on the ball and its upgrades and is generally below `BALL_WORLD_MAX_SPEED`. Tier 0's floor and width match today's base-stats numbers, so starting a run feels the same as today.

First-pass bands for the base ball at the default court (px/s): Tier 0 floor 225, ceiling ~390; Tier 1 floor ~340, ceiling ~520; Tier 2 (top) floor ~470, ceiling ~620 (the base ball's max). A stronger ball's top-tier ceiling sits higher, closer to `BALL_WORLD_MAX_SPEED`. Store tier bounds as fractions of the derived world max rather than frozen px/s, so widening the court rescales the whole ladder without hand-editing entries.

No tier, no item, no effect can promote the ball past `BALL_WORLD_MAX_SPEED`.

### Tier-completion event

Reaching a tier ceiling fires `on_tier_completed(tier_index)` on the item effect bus, drops `ball.speed` back to the new tier's floor, and continues the rally. The event payload carries the completed tier index so effect outcomes and reward handlers can scale their response. The first time a ball reaches a given tier, the completion also upgrades the ball. Completing the top tier additionally opens the final consolidation window; see 20a for its framing and reward payload.

### The final consolidation window

Completing a non-top tier hands off to the next band. The top tier has nothing above it, so completing it instead opens the final consolidation window: an extra speed range stacked above the ball's max, up to `BALL_WORLD_MAX_SPEED`. The final consolidation range is a property of the ball, so a stronger ball (higher max) gets a shorter window, since the world max is one hard line for every ball. Inside the window the ball keeps climbing hit by hit through the extra range; it does not snap to a single speed and it never exceeds `BALL_WORLD_MAX_SPEED`. The window holds while the rally is alive and ends on a miss. There is no cooldown timer; the rally ends the window the only way a rally ever ends, by a miss.

### Reset behaviour

- **Miss** resets tier to 0 and speed to Tier 0 floor, matching today's `ball.reset_speed` semantics. A miss during the final consolidation window is a normal miss; the banked reward is already the player's (see 20a).
- **Tier completion** sets tier to `tier + 1` and speed to the new tier's floor. Current speed does not carry across tiers; the drop is the reset beat.
- **Half-streak items** (Cadence's existing `on_miss` / halve outcome) still halve `_volley_count` on miss. They now also set tier to `floor(current_tier / 2)` and speed to the floor of that tier, so halving is proportional across the new ladder.

### Tier-aware ball state

`Ball` gains `current_tier: int` and `tier_floor` / `tier_ceiling` derived from `current_tier` against a `SpeedTierTable` resource. Each tier entry in the table carries `{ floor, ceiling, max_range, reward }`, where `max_range` is the per-tier promotion of the flat `ball_speed_max_range` stat from design/21-ball-dynamics.md. Tier 0's `max_range` holds the existing flat value from design/21-ball-dynamics.md's base-stats tuning surface, so that surface keeps its meaning and lives on the Tier 0 entry. `increase_speed` and `set_speed_for_streak` clamp against `tier_ceiling` instead of `max_speed`. Crossing `tier_ceiling` triggers `_advance_tier` which emits `tier_advanced(new_tier)` and `on_tier_completed` through `ItemManager.process_event`.

`speed_changed` grows to carry tier floor and ceiling instead of global min and max, so the speed bar can render the current band. `at_max_speed_changed` is repurposed to fire only on final consolidation entry/exit. The Cadence "ceiling outcome" (which currently latches on `on_max_speed_reached`) is out of scope here: Cadence's interaction with the tier model lives in its own tickets (SH-449 names the lifted cap and on-whistle consolidate as L2/L3; SH-59 the L3 burst). This work only retires the dead `on_max_speed_reached` trigger.

## Items under the tier model

The four items that currently shape ball speed keep their fantasy. Each stops trying to slide a single linear ceiling and starts interacting with the tier stack.

### Cadence

Current: oscillates `ball_speed_offset` within `ball_speed_max_range`; on `on_max_speed_reached` raises `ball_speed_max_range`.

Out of scope here. The oscillation feel effect is untouched. Cadence's tier interaction (its lifted cap and on-whistle consolidate) lands in SH-449 and SH-59, which own the item end to end. This work only retires the dead `on_max_speed_reached` trigger; whether Cadence retargets to `on_tier_completed` is that ticket's call.

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

- Full speed stack (Court Lines + Training Ball + Wrist Brace at cap): Tier 0 starts higher, climbs compress, ceilings hold. The final consolidation window becomes reachable inside a short rally. This is the new power fantasy. Without tiers, the same stack today sends speed arbitrarily high and breaks the paddle.
- Training Ball alone: Tier 0 compression only. Stops interacting with the tier ladder above Tier 0, which is what "early-game smoothing" items should do.

## Court width

The court's crossing distance sets the fun ceiling, so court width is a tunable rather than a baked scene layout. `CourtConfig` gains `court_half_width` (default 300, matching today's spawns); `Court` positions the player and partner spawns, miss zones, and right wall from it at startup instead of trusting authored marker positions. The markers stay in the scene for editor preview; runtime truth comes from config.

`BALL_WORLD_MAX_SPEED` and the tier bounds derive from it: `crossing = 2 * court_half_width`, `world_max = crossing / fair_crossing_seconds` (about 0.8s). At the default 300 this reproduces the 720 ceiling. Widen the court and the fair ceiling rises with the crossing; past about 860px/s the collider-face dial (above) is what keeps it tunnel-safe.

## Migration notes

- `ball_speed_max_range` stays as a tuning surface; it is promoted into a per-tier `max_range` field on `SpeedTierTable` rather than deleted. The flat value from design/21-ball-dynamics.md rides on the Tier 0 entry so existing tuning and tests keep their meaning; the tiers above each declare their own `max_range` alongside `floor`, `ceiling`, and `reward`. The table is owned by `GameRules`. Existing callers that read `ball_speed_max_range` read `SpeedTierTable.get_tier(current_tier).max_range` (or `.get_tier(0).max_range` for the base-stats tuning surface).
- Court Lines' `ball_speed_max_range` stat outcome is rewritten to a new `RaiseFloorSpeedOutcome`. Training Ball and Wrist Brace unchanged. Cadence is out of scope (SH-449 / SH-59).
- Court's `_on_ball_at_max_speed_changed` splits into `_on_ball_tier_advanced` (fires per tier) and `_on_ball_final_consolidation_changed` (fires on final consolidation entry/exit). `on_max_speed_reached` as an event name is retired; `on_tier_completed` replaces it.
- `ball.reset_speed` stays as miss behaviour. `ball.advance_tier` is new. `ball.set_speed_for_streak` clamps against `tier_ceiling` of the tier implied by streak count, which the tier table answers.
- No save compat shim. Items in flight at migration time reload against the new data and pick up the new behaviour.

## Open questions

- CCD per-body cost on the web export, if we need to reach for it. Needs a frame-budget measurement in the prototype before committing to CCD as the way past the discrete-step ceiling.
- Do Partners care about tier? Martha's current numbers do not touch speed, but a future Partner could want an `on_final_consolidation_hit` outcome. The event bus should accept it without special casing.

## Acceptance criteria mapping

- World max identified and named. `BALL_WORLD_MAX_SPEED` exists, set by the lower of the fun ceiling (court crossing) and the physics floor (60Hz tunnelling against the collider face), and derives from court width.
- CCD evaluated as a pressure valve available if the ceiling proves too tight in play.
- Tier progression designed. Three tiers (tunable); hits-per-climb falls out of base increment and per-tier `max_range`.
- Reset behaviour defined. Miss to Tier 0 floor. Tier completion to next tier floor. Final consolidation window ends on a miss only.
- Existing-item interactions documented. Court Lines and Training Ball re-expressed against the tier stack; Wrist Brace unchanged; Cadence deferred to SH-449 / SH-59.
- Narrative framing and reward ladder live in [20a Ball Speed Tier Progression](20a-ball-speed-tier-progression.md).
