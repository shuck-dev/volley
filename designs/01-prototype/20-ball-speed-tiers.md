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

Godot's 2D physics in this project runs at the engine default 60 ticks per second. `project.godot` does not override `physics/common/physics_ticks_per_second`.

Per-frame travel at 60 Hz is `speed / 60` pixels. The ball's collider is a `CircleShape2D` scaled to 1.2, giving an effective radius of roughly 12 px. The thinnest wall is 36 px. Paddle colliders are 36 px wide on the hit axis; Martha's is 40 px. Min paddle size on the long axis is `paddle_size_min = 45`.

Tunneling risks, in order of how quickly they bite:

- Paddle face, ball and paddle approaching each other. Closing speed can be `ball_speed + paddle_speed` (base `paddle_speed = 560`). Per-frame closing distance has to stay below `ball_radius + paddle_thickness / 2` with a margin, or the ball skips across the paddle face. At 60 Hz, keeping closing distance under about 30 px per frame is comfortable.
- Paddle edge, shrunk paddle. A paddle at `paddle_size_min = 45` is only 22 px from centre to each short end. Missing the edge because the ball clipped past it in one tick is the second failure mode.
- Walls. 36 px thick plus a 12 px ball gives 48 px of contact depth. The ball is the last thing to tunnel a wall.

A conservative world ceiling that keeps all three safe, including a Wrist Brace-boosted ramp and a moving paddle:

**`BALL_WORLD_MAX_SPEED = 1800` px/s.**

At 1800 px/s the ball travels 30 px per frame. Add the player paddle moving at `paddle_speed = 560` straight into the ball and closing per frame is about 39 px; with a 36 px paddle and 12 px ball radius that still leaves a 9 px overlap margin even at worst-case alignment. A shrunken 45 px paddle hit edge-on still has a 3-4 px margin at the corner, which is uncomfortable but survivable.

Higher than that and edge catches on minified paddles become unreliable at the default discrete step.

**No stacked item, no effect outcome, no debug cheat may push `ball.speed` above `BALL_WORLD_MAX_SPEED`.** This is a physics guarantee, not a balance number.

### Continuous collision detection as a pressure valve

Godot 4.6.2 ships two continuous collision detection modes on `RigidBody2D.continuous_cd`: `CCD_MODE_CAST_RAY` casts the body's motion as a ray (cheap, suits small fast bodies), and `CCD_MODE_CAST_SHAPE` casts the full collider shape along the motion vector (heavier, more accurate, per Godot 4 physics docs). Either mode solves tunnelling geometrically by resolving the first contact along the swept path rather than only sampling at the end of each physics tick, and either could in principle lift the hard speed ceiling.

CCD is not free. Each enabled body adds a per-frame broadphase and narrowphase query against the swept volume, and the cost lands on the physics thread. In this project the web export runs on the main thread (single-threaded physics, no `physics/common/physics_jitter_fix` relief), so that cost reads directly in the frame budget on Volley!'s busiest target. It is a valve we open on purpose, not a default.

Recommendation: keep `BALL_WORLD_MAX_SPEED = 1800` px/s as the uncontested ceiling while `continuous_cd = CCD_MODE_DISABLED`. Enable `CCD_MODE_CAST_RAY` on the ball at Tier 2 entry, promote to `CCD_MODE_CAST_SHAPE` at Tier 3 entry, and disable on tier reset. A later spike can evaluate raising `BALL_WORLD_MAX_SPEED` once we have a web-build frame budget to pay for CCD; until then the ceiling stands.

## Tier math

Speed progression becomes a ladder of tiers. Each tier has its own floor and ceiling; reaching a ceiling fires a tier event and drops the ball to the floor of the next tier. The reward that fires alongside the event is owned by the companion progression doc.

### Tier 0 to Tier 3

| Tier | Floor (px/s) | Ceiling (px/s) | Band width | Hits to climb |
|---|---|---|---|---|
| 0 | 450 | 790 | 340 | ~20 |
| 1 | 790 | 1100 | 310 | ~18 |
| 2 | 1100 | 1450 | 350 | ~20 |
| 3 | 1450 | 1800 | 350 | ~20 |

Tier 0 matches today's base numbers exactly: floor 450, width 340, increment 17. Players starting a run feel the same ramp they feel now.

Hits-to-climb uses the base `ball_speed_increment = 17`. With Wrist Brace at level 5 (+40 increment effect total) the ramp compresses, which is the item's whole point; tier structure does not fight it.

Tier ceilings compound deliberately: each band is a bit wider than the last, so the later tiers feel harder-earned without the absolute ceiling running away. The final band tops out at `BALL_WORLD_MAX_SPEED`. No tier, no item, no effect can promote the ball past Tier 3 ceiling.

### Tier-completion event

Reaching a tier ceiling fires `on_tier_completed(tier_index)` on the item effect bus, drops `ball.speed` back to the new tier's floor, and continues the rally. The event payload carries the completed tier index so effect outcomes and reward handlers can scale their response. Tier 3 completion additionally opens a Peak window; see 20a for its framing and reward payload.

### Reset behaviour

- **Miss** resets tier to 0 and speed to Tier 0 floor, matching today's `ball.reset_speed` semantics.
- **Tier completion** sets tier to `tier + 1` and speed to the new tier's floor. Current speed does not carry across tiers; the drop is the reset beat.
- **Peak window end without miss** drops speed and tier to 0 but does not count as a miss. The rally continues. Call this the "cooldown" reset: no penalty events fire, `_volley_count` is preserved, the Court just feels the speed drop.
- **Peak window end by miss** behaves as a normal miss: tier 0, volley count 0 (or halved if a halve-streak item is active, same as today).
- **Half-streak items** (Cadence's existing `on_miss` / halve outcome) still halve `_volley_count` on miss. They now also set tier to `floor(current_tier / 2)` and speed to the floor of that tier, so halving is proportional across the new ladder.

### Tier-aware ball state

`Ball` gains `current_tier: int` and `tier_floor` / `tier_ceiling` derived from `current_tier` against a `SpeedTierTable` resource. `increase_speed` and `set_speed_for_streak` clamp against `tier_ceiling` instead of `max_speed`. Crossing `tier_ceiling` triggers `_advance_tier` which emits `tier_advanced(new_tier)` and `on_tier_completed` through `ItemManager.process_event`.

`speed_changed` grows to carry tier floor and ceiling instead of global min and max, so the speed bar can render the current band. `at_max_speed_changed` is repurposed to fire only on Peak entry/exit; the Cadence "ceiling outcome" (which currently latches on `on_max_speed_reached`) moves to `on_tier_completed` with a tier filter.

## Items under the tier model

The four items that currently shape ball speed keep their fantasy. Each stops trying to slide a single linear ceiling and starts interacting with the tier stack.

### Cadence

Current: oscillates `ball_speed_offset` within `ball_speed_max_range`; on `on_max_speed_reached` raises `ball_speed_max_range` by 15 up to +75.

New: oscillation stays (it is a feel effect, not a ceiling effect). The ceiling-raising outcome becomes a **tier-skip chance**. On `on_tier_completed`, Cadence has a per-level chance (15/30/45%) to skip the next tier's climb and drop straight into the tier after. At high levels this reliably vaults the player into Tier 3 Peak faster. "Don't stop. Won't stop" reads as "keep the tempo, skip the queue," and the item keeps rewarding long rallies without raising the absolute cap.

### Court Lines

Current: flat `+50` per level to `ball_speed_max_range`, up to level 10 (`+500`).

New: **widens tiers** without raising their ceilings. Each level adds a small amount (+5 px/s?) to tier floors 1-3, so bands start higher but still end at the same fixed ceilings. Climbing tiers 1-3 takes fewer hits. At level 10 a Tier 3 run starts with the ball already at 1500 px/s and only needs ~18 hits to Peak. The flavour ("the ceiling keeps moving") shifts to "the start line keeps moving", which reads cleaner.

### Training Ball

Current: flat `+30` per level to `ball_speed_min`, up to level 10 (`+300`).

New: unchanged in shape. Training Ball raises Tier 0 floor only; it does not affect Tier 1+ floors. Base serves come in faster and Tier 0 finishes quicker, but the item stops colliding with the tier structure above. "Already moving" still fits.

### Wrist Brace

Current: `+8` per level to `ball_speed_increment`, with a `paddle_size` percentage penalty.

New: unchanged. Wrist Brace compresses every tier's hits-to-climb and trades paddle size for ramp speed. It is the "do the climb faster" item; layering it under a tier model is exactly what we want.

### Interactions at the extremes

- Court Lines 10 + Training Ball 10 + Wrist Brace 10: Tier 0 floor is 750, Tier 3 ceiling is still 1800, climbs are ~8 hits per tier. Peak is reachable inside the first 30 hits of a rally. This is the new power fantasy. Without tiers, the same stack today sends speed arbitrarily high and breaks the paddle.
- Cadence 3 with any speed stack: tier-skip chance up to 45% means the average Peak-to-Peak interval shrinks well below 60 hits, which is the Cadence identity under this model.
- Training Ball alone: Tier 0 compression only. Stops interacting with the tier ladder above Tier 0, which is what "early-game smoothing" items should do.

## Migration notes

- `ball_speed_max_range` as a stat key disappears. `SpeedTierTable` resource replaces it and is owned by `GameRules`. Existing tests that read `ball_speed_max_range` become tests against `SpeedTierTable.get_tier(n).ceiling`.
- Cadence's `on_max_speed_reached` outcome is rewritten to `on_tier_completed` with a tier filter. Court Lines' `ball_speed_max_range` stat outcome is rewritten to a new `widen_tier_floors` outcome. Training Ball and Wrist Brace unchanged.
- Court's `_on_ball_at_max_speed_changed` splits into `_on_ball_tier_advanced` (fires per tier) and `_on_ball_peak_changed` (fires on Peak entry/exit). `on_max_speed_reached` as an event name is retired; `on_tier_completed` replaces it.
- `ball.reset_speed` stays as miss behaviour. `ball.advance_tier` is new. `ball.set_speed_for_streak` clamps against `tier_ceiling` of the tier implied by streak count, which the tier table answers.
- No save compat shim. Items in flight at migration time reload against the new data and pick up the new behaviour.

## Open questions

- CCD per-body cost on the web export. Needs a frame-budget measurement at Tier 3 + CCD_MODE_CAST_SHAPE before the recommendation locks in.
- Do Partners care about tier? Martha's current numbers do not touch speed, but a future Partner could want an `on_peak_hit` outcome. The event bus should accept it without special casing.

## Acceptance criteria mapping

- Hard physics ceiling identified and documented. `BALL_WORLD_MAX_SPEED = 1800` px/s, justified against the 60 Hz tick, paddle collider width, and min paddle size.
- CCD evaluated as a pressure valve. `CCD_MODE_CAST_RAY` at Tier 2, `CCD_MODE_CAST_SHAPE` at Tier 3, disabled on reset; web-thread cost called out as the gate on raising the ceiling.
- Tier progression designed. Four tiers, ~18-20 hits per climb at base increment.
- Reset behaviour defined. Miss to Tier 0 floor. Tier completion to next tier floor. Peak end without miss drops to Tier 0 floor without counting as a miss.
- Existing-item interactions documented. Cadence, Court Lines, Training Ball, Wrist Brace all re-expressed against the tier stack.
- Narrative framing and reward ladder live in [20a Ball Speed Tier Progression](20a-ball-speed-tier-progression.md).
