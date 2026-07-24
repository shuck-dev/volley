# Cadence

Cadence oscillates ball speed between half, normal, and double on a timer, independent of paddle hits.

## Mechanism

`resources/items/cadence_ball.tres` defines one effect: trigger `always`, one outcome, `StatShiftOutcome` targeting `ball_speed_scale`.

`StatShiftOutcome.apply()` builds a `StatShift` (`scripts/items/effect/outcomes/stat_shift.gd`), a state machine cycling `NORMAL -> DOUBLE -> HALF -> NORMAL`, holding each mode for a random duration between `min_interval` and `max_interval`. `get_offset()` returns the mode's multiplier as a delta from 1.0: `-0.5` at half, `0.0` at normal, `+1.0` at double. `EffectState.get_percentage_offset` sums this with ordinary percentage modifiers for the same stat key.

`BallEffectProcessor` holds two speed fields:

- `ball.speed`: the clamped, unshifted progression value. Tier logic (`increase_speed()`, `advance_tier()`, `sync_base_speed()`) reads and writes only this field.
- `effect_processor.scaled_speed`: `ball.speed` multiplied by `1.0 + get_percentage_offset(&"ball_speed_scale", ball.item_key)`. `Ball` reads this field wherever it sets `linear_velocity`.

`refresh_scaled_speed()` recomputes `scaled_speed` from the current `ball.speed` and the current shift offset. It runs every frame from `_apply_speed_offset()`, and again from `Ball._apply_speed()` on hit, tier-advance, and miss-reset, so `scaled_speed` never carries a stale multiplier between those events.

Tier completion compares `ball.speed` (not `scaled_speed`) against `tier_ceiling`. Cadence's multiply applies after that comparison and does not affect tier-advance timing, the per-tier soul reward, or the first-reach ball upgrade.

## Files

- `resources/items/cadence_ball.tres`: item definition, one effect, one `StatShiftOutcome` on `ball_speed_scale`.
- `scripts/items/effect/outcomes/stat_shift.gd`: the half/normal/double state machine.
- `scripts/items/effect/outcomes/stat_shift_outcome.gd`: builds a `StatShift` from the resource's exported fields on `apply()`.
- `scripts/items/effect/shift_repository.gd`: stores active shifts, sums offset per stat key and per ball instance.
- `scripts/entities/ball/effect_processor.gd`: `_apply_speed_offset()`, `refresh_scaled_speed()`, `scaled_speed`.
- `scripts/items/cadence_art.gd`: particle cue tied to `StatShift.shifted`, reconnected on level-up.
