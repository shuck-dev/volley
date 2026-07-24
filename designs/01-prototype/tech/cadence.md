# Cadence

A ball whose speed breathes. Every few seconds it holds normal, then swings to double, then to half, cycling on its own timer. The player never presses anything for it; the ball just gets faster or slower while the rally keeps going.

## The mechanic

`resources/items/cadence_ball.tres` carries one effect, one trigger, one outcome. The trigger is `always`, so the effect registers the moment the ball is owned and never has to wait on a condition. The outcome is a single `StatShiftOutcome` targeting `ball_speed_scale`.

`StatShiftOutcome.apply()` builds a `StatShift` (`scripts/items/effect/outcomes/stat_shift.gd`): a small state machine cycling `NORMAL -> DOUBLE -> HALF -> NORMAL`, holding each mode for a random duration between `min_interval` and `max_interval`. `get_offset()` reads the mode's multiplier (0.5, 1.0, 2.0) and reports it as a delta from 1.0: `-0.5` at half, `0.0` at normal, `+1.0` at double. `EffectState.get_percentage_offset` sums this alongside ordinary percentage modifiers, so `ball_speed_scale` behaves exactly like any other percentage stat: it just happens to move on a timer instead of an item purchase.

`BallEffectProcessor` is where the shift actually reaches the ball. `ball.speed` stays the clamped, unshifted progression value, the same field every other ball's tier logic reads and writes. A second field, `effect_processor.scaled_speed`, carries the value the ball actually moves at: the clamped speed multiplied by `1.0` plus Cadence's percentage offset. `Ball` reads `scaled_speed`, not `speed`, wherever it sets its velocity.

The split matters. An earlier version wrote the scaled value straight into `ball.speed`, and the routine that rebuilds the ball's base speed after every hit and tier-advance reads `ball.speed` back out to do it. A Cadence ball's own scale was feeding back into the value the next hit built on, so a run of hits under a steady double compounded the ball far past what two hits should add. Keeping `ball.speed` as the single unshifted source of truth, and `scaled_speed` as a pure read of it, closes that loop. Tier progression clamps first, exactly as it does for every other ball. Cadence's multiply happens after, on the clamped result, and never feeds back into it.

## Why the shift lives outside the clamp

The first draft of this effect shifted `ball_speed_min` directly, with `ball_speed_max_range` as the shift's range key. That moved the tier's floor without moving its ceiling, so half squeezed the playable window instead of sliding it, and in the worst case pinned the ball against a floor it could no longer fall below. The fix was not a wider range or a second clamp. It was accepting that the clamp should never see the shift at all.

`tier_floor` and `tier_ceiling` stay exactly what the speed-tier design says they are: the fraction of the court's world-max speed for the current tier, nothing more. `increase_speed()` compares the ball's *unshifted* base speed against `tier_ceiling` to decide when a tier completes, so Cadence's multiply never touches tier-advance timing, the once-per-tier soul reward, or the first-reach ball upgrade. All of that fires at the same real crossings it always would. The shift is a second layer painted on top of a speed value that has already finished being a tier speed.

## What decoupling would have needed

An earlier version of this problem asked whether tier progression should decouple from speed entirely: advance on hit-count instead of a speed threshold, so a halved ball couldn't stall a rally by never reaching its ceiling. `designs/01-prototype/20-ball-speed-tiers.md` already answers this. Tier width is tied to court geometry, not hit count; "about ten hits a tier" is the felt result of `speed_increment` against a band's width, not a rule the game enforces directly. Rebuilding tiers around hit count would have changed how every ball in the game progresses, not just Cadence's. The post-clamp multiply solves Cadence's actual problem, a shift with nowhere to go, without asking the rest of the ball system to change what a tier means.

## Files

- `resources/items/cadence_ball.tres`: the item definition, one effect, one `StatShiftOutcome` on `ball_speed_scale`.
- `scripts/items/effect/outcomes/stat_shift.gd`: the half/normal/double state machine.
- `scripts/items/effect/outcomes/stat_shift_outcome.gd`: builds a `StatShift` from the resource's exported fields on `apply()`.
- `scripts/items/effect/shift_repository.gd`: stores active shifts, sums their offset per stat key and per ball instance.
- `scripts/entities/ball/effect_processor.gd`: `_apply_speed_offset()`, where the post-clamp multiply happens.
- `scripts/items/cadence_art.gd`: the particle cue tied to `StatShift.shifted`, reconnected on level-up so a re-registered ball doesn't keep listening to a discarded shift.
