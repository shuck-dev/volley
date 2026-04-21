# Ball Dynamics

Design review of the ball physics model: what stays, what changes, and why. Answers the seven questions raised in SH-83 so that ball feel and the planned item effects (`Dead Weight`, `The Call`, `The Stray`, `Cadence`) can be implemented against a single coherent model.

**Points:** Spike
**Dependencies:** [Balls on the Court](08-balls.md), [Partner AI](17-partner-ai.md), [Make Fun Pass](16-make-fun.md), [Effect System](07-effect-system.md).

---

## Context: where the ball is today

The live implementation lives in `scripts/entities/ball.gd` and `scripts/entities/ball_effect_processor.gd`.

- `Ball` extends `RigidBody2D` with `lock_rotation = true`, `linear_damp = 0.0`, and the court's `PhysicsMaterial` handling wall and paddle reflections.
- Each physics frame the ball re-normalises its velocity and scales to a target `speed`. This clamps the magnitude the engine would otherwise drift through its integrator.
- `BallEffectProcessor.process_frame` reads live stats from `ItemManager` (`ball_speed_min`, `ball_speed_max_range`, `ball_speed_increment`, `ball_speed_offset`, `ball_magnetism`) and applies magnetism (a small steering force toward the nearest paddle).
- On paddle contact, `_on_body_entered` calls `paddle.on_ball_hit()` then `effect_processor.process_hit()`. The hit path already calls `_apply_return_angle_influence`, but that function biases the post-bounce velocity toward horizontal based on a single scalar stat. It does not read the paddle's position or the hit offset.
- `speed` starts at `ball_speed_min` (450) and advances by `ball_speed_increment` (17) per paddle hit up to `ball_speed_min + ball_speed_max_range` (790). `set_speed_for_streak` lets the rally restore on pickup.
- Partner AI (`scripts/core/paddle_ai_math.gd::predict_intercept`) models the ball as a straight line with perfect wall reflections, capped at 20 reflection iterations.

The ticket's stated numbers (400-700, +15) are slightly out of date: live stats are 450-790, +17. Feel conclusions below use the live numbers.

---

## Q1. Return angle control

**Recommendation:** paddle-offset drives the return angle. Repurpose the `return_angle_influence` stat as the strength knob for that mapping. Remove the current "bias toward horizontal" behaviour; it is a placeholder that fights the player's intent.

Concretely, on `process_hit`:

```
hit_offset = clamp((ball.y - paddle.y) / (paddle_height / 2), -1, 1)
max_deflection_radians = deg_to_rad(60)   # ceiling, not default
target_angle = hit_offset * max_deflection_radians * return_angle_influence
new_dir.x = sign(current_dir.x) * cos(target_angle)
new_dir.y = sin(target_angle)
ball.linear_velocity = new_dir * ball.speed
```

Design properties:

- `return_angle_influence = 0` preserves the pure-reflection feel (current base stat default).
- `return_angle_influence = 1` gives full Breakout/Arkanoid-style control: edge hits reach 60 deg, centre hits go flat.
- The stat stays additive like every other `ItemManager` stat, so items can nudge it (e.g. a "Fine Tuning" passive lifts player return angle; a debuff trims it).
- Hit offset is derived from the current paddle collision-shape height (`_collision_shape.size.y`), so `paddle_size` changes (shrink effects, levelling) automatically rescale the mapping.

This subsumes the existing `_apply_return_angle_influence` implementation. The horizontal-bias version it replaced was never shipped as an item and was not observable in normal play, so removing it has no save-compat cost (per [no save backward-compat shims](../process/ticket-writing.md) rule; just delete the old branch).

**Acceptance hooks:** paddle position influences return angle; `return_angle_influence` drives it.

---

## Q2. Speed curve feel

**Recommendation:** keep the curve linear in code; move the feel decision entirely into `BaseStatsConfig` by treating `ball_speed_min`, `ball_speed_max_range`, and `ball_speed_increment` as the tuning surface. No non-linear curve in the engine.

Rationale:

- The current span is 450 to 790 at +17 per hit. That is 20 hits from floor to ceiling. On an average rally this is roughly 10-15 seconds of play, which is where the "rally pressure" beat should land. Rallies that run longer than that are already at the exciting end.
- A diminishing curve (e.g. `speed += increment * (1 - t)`) makes the top end feel like a wall the rally can never cross. That undercuts the "we pushed through" moment that caps a long rally.
- Items already manipulate speed additively through `ball_speed_offset`, and per-hit increment is a stat, so a future "slow burn" partner can ship a non-linear feel by owning those knobs without the core needing a curve type.
- Keeping the model linear keeps the AI prediction stable (Q6) and the streak-restore path (`set_speed_for_streak`) a one-line calculation.

If future playtesting shows the ceiling arrives too fast, the levers are: raise `ball_speed_max_range`, lower `ball_speed_increment`, or add a per-streak-bracket offset via an item. None require a code change to the ball.

**Acceptance hooks:** speed curve reviewed, recommendation is keep linear and tune via base stats.

---

## Q3. Spin or curve

**Recommendation:** out of scope for the prototype. Ship the mechanic only as an item-driven effect, not as a baseline ball behaviour.

Reasons:

- Constant curve on every ball makes the court read as unpredictable noise rather than a skill surface. The player cannot distinguish "this ball curved because I hit it poorly" from "this ball curved because the ball does that." We lose the teaching signal of the return-angle control above.
- Curve on top of predictive AI (Q6) forces the AI to either track live (Tier 1, regresses partner feel) or simulate curve in its projection (expensive and brittle).
- Items that want to curve balls (Dead Weight's gravity well is the designed path) already have a clean hook: per-frame acceleration applied in `BallEffectProcessor.process_frame`, driven by an item-owned node. That keeps curve scoped to moments the player opted into.

When an item does introduce curve, it should:

- Apply its acceleration through `process_frame`, then renormalise via the existing `linear_velocity = linear_velocity.normalized() * speed` clamp so the ball's top speed remains the stat-driven ceiling.
- Expose a short-lived "curve field" region (gravity well radius, deflector cone) rather than a global scalar. Local effects are readable; global curve is not.

**Acceptance hooks:** spin/curve decision is out of scope for baseline ball; in scope only as item-driven local fields.

---

## Q4. Physics model suitability

**Recommendation:** keep `RigidBody2D`. The friction the ticket describes is real but small, and the alternatives cost more than they save.

What `RigidBody2D` gives us today:

- Free collision resolution against paddles, walls, and any future `StaticBody2D` fixtures (posts, deflectors, bumpers).
- One shared `PhysicsMaterial` controls bounciness across every surface; items that add surfaces get correct reflection for free.
- `contact_monitor = true` + `_on_body_entered` gives us a signal-driven hit path that items already consume.

What it costs:

- Per-frame renormalisation to pin the speed.
- Two fields on the `Ball` (`speed`, `linear_velocity`) that have to stay in sync.
- An effect processor node holding the state machine that a kinematic version would hold in the ball itself.

A kinematic rewrite (`CharacterBody2D` + manual reflection) would remove the renormalisation but require us to re-implement wall reflection, paddle reflection with the Q1 offset formula, tunnelling guards for the top speed, and collision-shape queries for every static fixture items add later. That is a lot of surface for a marginal speed-clamp win, and we already have the clamp working.

**Tunnelling check.** At 790 px/s and 60 Hz the ball travels ~13 px per physics tick. Paddle thickness and wall thickness are both well above that. If future items push the speed cap higher, switch `continuous_cd` on the ball to `CCD_MODE_CAST_SHAPE` rather than moving to kinematic.

**Acceptance hooks:** physics model reviewed, recommendation is keep `RigidBody2D` with the existing speed clamp.

---

## Q5. Item interaction audit

Each planned ball-affecting item checked against the recommended model.

### Dead Weight (gravity well, SH-56)

Clean fit. The well spawns as a scene with a position and a radius stat. `BallEffectProcessor.process_frame` grows a second pass (after magnetism, before speed-limit sync) that applies a per-frame acceleration toward any active well within range:

```
for well in active_wells:
    to_well = well.global_position - ball.global_position
    distance = to_well.length()
    if distance < well.radius:
        falloff = 1 - (distance / well.radius)
        ball.linear_velocity += to_well.normalized() * well.strength * falloff * delta
```

The existing renormalise step at the end of `_physics_process` preserves the speed ceiling. No new field on `Ball`; wells register with `BallEffectProcessor` the same way paddles do today.

### The Call (deflection, SH-55)

Clean fit. Deflection is a one-shot redirect on demand. Add `Ball.deflect(target_direction: Vector2)` that sets `linear_velocity = target_direction.normalized() * speed`. The Call's outcome invokes it. No physics rewrite.

### The Stray (multi-ball, SH-54)

Clean fit. `SpawnBallOutcome` (already designed in `08-balls.md`) instantiates additional `Ball` scenes. Each one owns its own `BallEffectProcessor`, so effects scale per-ball. The only shared state is `ItemManager` stats, which every ball reads fresh each frame. No coupling across balls.

One note for the ticket that implements it: AI prediction needs to know which ball to chase. The partner AI should track the nearest ball by projected intercept time, not by spawn order, so that temporary balls do not get ignored (see Q6).

### Cadence (speed oscillation)

Clean fit. Add a small sine-driven additive term inside `_sync_speed_limits` alongside `ball_speed_offset`:

```
oscillation = ItemManager.get_stat(&"ball_speed_oscillation_amp") * \
              sin(TAU * ItemManager.get_stat(&"ball_speed_oscillation_hz") * time)
```

`time` is a per-ball accumulator so multiple balls do not beat against each other. Because this rides on the same `_base_speed + offset` stack, it composes with every other speed-modifying stat without special cases.

**Summary:** all four planned items slot into the current processor-plus-stats model. None requires touching `Ball` itself except for The Call's one-line method.

**Acceptance hooks:** item interaction audit covers each planned ball effect against the proposed model.

---

## Q6. AI prediction compatibility

**Recommendation:** keep linear-with-reflections prediction for the baseline ball. Do not try to simulate curve or gravity in the predictor. Instead, when an item introduces a local curve field, treat the prediction error as designed partner behaviour and surface it as such.

Why that is acceptable:

- The rally without items is straight-line with wall reflections. The current predictor is exact for this case.
- The only baseline change this spike recommends is paddle-offset return angle (Q1). That affects the ball's direction at the instant of a paddle hit, which is already an event the predictor treats as "recompute from here." No upstream prediction goes wrong.
- Local curve fields (wells, deflectors) break prediction on purpose. A partner running Dead Weight should miss more; the item's read is "this slows my partner down," which is correct partner feel and matches how the player experiences it. "Partner breaks on gravity" is the feature.
- A partner can opt out of the confusion via a stat, e.g. `ai_intercept_uses_wells` is a boolean the predictor checks; an upgraded partner gets a smarter projection. That is a shippable progression hook rather than a tech debt.

Multi-ball needs a small predictor change: today the partner AI targets one ball. When more than one is live, it should pick the ball with the smallest positive time-to-intercept for the partner's lane. That is a scoring function, not a physics rewrite.

**Acceptance hooks:** AI prediction impact assessed.

---

## Q7. Bounce angle variance

**Recommendation:** drop SH-49's random-offset-on-bounce. Systemic variance from paddle offset (Q1) and hit-streak speed (Q2) is enough to keep the rally from looking scripted, and random noise on wall bounces would fight the player's ability to read the ball.

What "enough variance" means here:

- Paddle offset makes every return the player's decision. Edge hits are steep; centre hits are flat. The player controls the mix.
- Speed increment means every rally's nth hit lands at a different speed, so even an identical trajectory plays out differently as the streak lengthens.
- Item fields (wells, deflection) are the source of surprise when the build asks for surprise.

Random bounce variance on walls cannot be attributed back to any player decision, so it reads as the game being inconsistent rather than the player being good. The existing SH-49 ticket should be closed out with this design as the rationale (or kept open as a "considered and declined" record, per the project's ticket-writing guide).

**Acceptance hooks:** bounce-angle variance decision is systemic (paddle offset + speed curve + item fields); no random noise on bounces.

---

## What this changes in code

A follow-up implementation ticket should cover exactly these edits:

1. Rewrite `BallEffectProcessor._apply_return_angle_influence` to use the Q1 paddle-offset formula. It needs the paddle that was hit, which `process_hit` does not currently receive. Pass the paddle through from `Ball._on_body_entered` so the processor has it.
2. Add `Ball.deflect(target_direction)` for SH-55.
3. Add a gravity-well registration surface to `BallEffectProcessor` (`register_well`, `unregister_well`) and a second pass in `process_frame` for SH-56.
4. Partner AI: switch ball selection from "the ball" to "nearest projected intercept" for SH-54.
5. Tests: unit-test the paddle-offset formula against known hit positions; extend `PaddleAIMath` tests only if the selection function becomes non-trivial.

All four items above can ship independently and against current main. Nothing about this spike blocks landing SH-54, SH-55, or SH-56 separately.

---

## Related tickets

- [SH-49](https://github.com/shuck-dev/volley/issues/49) (ball bounce angle variance): close or decline per Q7.
- [SH-54](https://github.com/shuck-dev/volley/issues/54) (The Stray, multi-ball): compatible, needs the nearest-ball predictor change (Q6).
- [SH-55](https://github.com/shuck-dev/volley/issues/55) (The Call, deflection): compatible, needs `Ball.deflect`.
- [SH-56](https://github.com/shuck-dev/volley/issues/56) (Dead Weight, gravity well): compatible, needs well registration on the effect processor.
