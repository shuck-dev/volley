# Cadence

Cadence oscillates ball speed between half, normal, and double on a timer, independent of paddle hits.

## Mechanism

`resources/items/cadence_ball.tres` points `scene` at `scenes/balls/cadence_ball.tscn`, an inherited scene of `ball.tscn` whose root script is `CadenceBall` (`scripts/entities/ball/cadence_ball.gd`).

`CadenceBall` overrides `_setup_effect_processor()` to install a `CadenceBallEffectProcessor` (`scripts/entities/ball/cadence_ball_effect_processor.gd`) instead of the base `BallEffectProcessor`. The subclass owns the half/normal/double cycle directly: `process_frame()` advances a `_time_in_mode` timer against a random `_hold_duration` between `min_interval_seconds` and `max_interval_seconds` (exported, tuned in the scene), and steps `NORMAL -> DOUBLE -> HALF -> NORMAL` when the hold expires, emitting `mode_shifted`.

`BallEffectProcessor` holds two speed fields:

- `ball.speed`: the clamped, unshifted progression value. Tier logic (`increase_speed()`, `advance_tier()`) reads and writes only this field.
- `effect_processor.scaled_speed`: `ball.speed` multiplied by the current mode's multiplier (0.5 / 1.0 / 2.0). `Ball` reads this field wherever it sets `linear_velocity`.

`CadenceBallEffectProcessor.refresh_scaled_speed()` overrides the base implementation to multiply by its own mode instead of reading `EffectState`'s percentage offset. It runs every frame from `process_frame()`, and again from `Ball._apply_speed()` on hit, tier-advance, and miss-reset, so `scaled_speed` never carries a stale multiplier between those events.

Tier completion compares `ball.speed` (not `scaled_speed`) against `tier_ceiling`. Cadence's multiply applies after that comparison and does not affect tier-advance timing, the per-tier soul reward, or the first-reach ball upgrade.

`CadenceBall` listens to its own processor's `mode_shifted` signal and restarts `shift_cue` (a `CPUParticles2D` authored directly in `cadence_ball.tscn`) on every mode change.

## Files

- `resources/items/cadence_ball.tres`: item definition; `scene` points at `scenes/balls/cadence_ball.tscn`, `preview_art` at the lightweight shop/rack preview (`scenes/items/cadence.tscn`).
- `scenes/balls/cadence_ball.tscn`: inherited scene of `ball.tscn`; root script `CadenceBall`, sprite override, and `shift_cue` particles authored directly.
- `scripts/entities/ball/cadence_ball.gd`: `CadenceBall`, wires the particle cue to `mode_shifted`.
- `scripts/entities/ball/cadence_ball_effect_processor.gd`: `CadenceBallEffectProcessor`, the half/normal/double state machine and `refresh_scaled_speed()` override.
- `scripts/entities/ball/effect_processor.gd`: base `BallEffectProcessor`, `refresh_scaled_speed()`, `scaled_speed`.
