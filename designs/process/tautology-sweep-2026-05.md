# Tautology sweep on N-iteration tests (SH-415)

Spike following Cal's catch on `test_oscillation_never_drops_below_min_speed`: a 300-iteration physics-loop test whose fixture role default routed the item to STORED, so the production effect never registered and the assertion held on baseline state forever. The smell: a long simulation loop plus an assertion that could hold if the production code under test were stubbed to a no-op (or, in the clamp-boundary variant, an assertion structurally guaranteed by a `clampf` in the production path).

The method: enumerate candidates (for-in-range loops driving `_physics_process` / `process_frame`, await-frame chains, N-iteration sweeps), then for each, stub the production effect to no-op (or to the identity function for clamps) and re-run the test. If it still passes, the assertion was asserting nothing; rewrite or delete.

## Candidates audited

### `tests/unit/events/test_event_dispatch.gd:181`, `test_oscillate_stat_changes_value_over_time`

Fixture role default: oscillation registered via `EffectManager.register_source` with `always` trigger; effect IS applied through the production path.

Production effect: `OscillateStatOutcome.apply` adds a `StatOscillation` to `EffectState`, which `process_frame` advances each tick.

Stub-no-op outcome: FAILS as expected (loop completes without `found_different` ever set; `assert_true(found_different, ...)` fires).

Action: keep, no change. The early-break-on-different pattern is already non-tautological.

### `tests/unit/events/test_event_dispatch.gd:201`, `test_oscillate_stat_stays_within_amplitude`

Fixture role default: same as above; oscillation registered correctly.

Production effect: same oscillation; the test asserts `min_observed >= base - amplitude * range` and `max_observed <= base + amplitude * range` over 300 frames.

Stub-no-op outcome: SURVIVES. With `OscillateStatOutcome.apply` stubbed to `pass`, the oscillation never registers, the stat resolves to `base_value` on every frame, so `min_observed == max_observed == base_value` and both bounds trivially hold (since amplitude > 0). The assertion has no teeth.

Action: rewrite. Replaced the 300-frame Monte Carlo with a deterministic period-sweep via the new `_worst_absolute_offset_over_period` helper plus a tautology guard (`extreme >= effective_amplitude * 0.5`). Stub re-verified: rewrite now fails the no-op as it should.

### `tests/unit/events/test_event_dispatch.gd:231`, `test_oscillate_stat_scales_range_by_level`

Production effect: level-2 oscillation; per-frame assertion that current value sits inside `[base - 2*amplitude*range, base + 2*amplitude*range]`.

Stub-no-op outcome: SURVIVES. Constant `base_value` lies inside any non-degenerate range bounded around `base_value`.

Action: rewrite. Same pattern as the level-1 amplitude test: period-sweep plus tautology guard against the level-2 effective amplitude. Stub re-verified, rewrite catches the no-op.

### `tests/unit/events/test_event_dispatch.gd:332`, `test_unregister_stops_oscillation`

Production effect: oscillation registered, 60 frames advanced, source unregistered, then assert stat resolves to `base_value`.

Stub-no-op outcome: SURVIVES. If apply is a no-op the stat is `base_value` throughout the 60 frames and after unregister; the post-unregister equality is satisfied for the wrong reason.

Action: rewrite. Added an explicit `observed_active` tautology guard inside the pre-unregister loop, breaking as soon as the stat shifts away from base. The post-unregister assertion remains, but the new guard ensures the test only passes when oscillation actually ran in the first place. Stub re-verified.

### `tests/unit/items/test_cadence.gd:39`, `test_oscillation_active_after_purchase`

Production effect: purchase Cadence, which registers oscillation through the item manager; loop 60 frames looking for any deviation from base.

Stub-no-op outcome: FAILS as expected (no deviation, `found_different` stays false).

Action: keep, no change.

### `tests/unit/items/test_cadence.gd:57`, `test_oscillation_inactive_before_purchase`

Production effect: no oscillation registered (purchase has not happened); loop 60 frames, assert stat equals base.

Stub-no-op outcome: SURVIVES trivially because the test asserts a negative (stat should NOT change), and the stub also produces no change. This is not the bad kind of tautology: it is a regression guard against an accidental "oscillation active without purchase" path, and the test's intent is exactly "this should be a no-op." Negative-assertion regression guards are inherently survived by no-op stubs of the corresponding production code.

Action: keep, no change. Not in the same class of smell.

### `tests/unit/ball/test_ball.gd:200`, `test_oscillation_never_drops_below_min_speed`

This is the test Cal already rewrote and the model for the rest of this sweep. Already uses `StatOscillation.sample_at` directly with a tautology guard (`min_speed + worst_offset < min_speed` so the clamp must actually fire).

Action: keep, no change.

### `tests/unit/paddle/test_paddle_auto_play.gd:91`, `test_autoplay_speed_never_exceeds_configured_scale`

Production effect: `_track()` computes `max_speed = paddle_speed * speed_scale`, sets `target_velocity = sign(difference) * max_speed`, lerps `paddle.velocity.y` toward that target. The test loops 200 frames and asserts `abs(paddle.velocity.y) <= max_allowed + 0.01` every frame.

Stub-no-op outcome: SURVIVES. With `_track()` stubbed to `pass`, paddle velocity stays at 0; 0 <= max_allowed trivially. The upper bound is structurally satisfied by the lerp regardless: target is exactly `max_speed`, lerp from 0 toward max_speed never overshoots.

Action: rewrite. Added a peak-velocity tracker (`peak_observed`) inside the loop and a post-loop assertion that `peak_observed >= max_allowed * 0.95`, so the test now requires the paddle to actually drive toward the cap during pursuit. Stub re-verified: peak stays at 0, assertion fires.

### `tests/unit/paddle/test_partner_ai_controller.gd:138`, `test_speed_never_exceeds_configured_scale`

Same shape as the autoplay test: 50 settle frames, 50 sample frames, upper bound only. Same tautology, same rewrite (peak-velocity tracker plus convergence guard). Stub re-verified.

### `tests/unit/paddle/test_paddle_ai_math.gd:61`, `test_noise_bounded_by_two_sigma`

Production effect: `random_offset(noise_range)` runs Box-Muller, then wraps in `clampf(normal * noise_range, -noise_range * 2.0, noise_range * 2.0)`. The test loops 1000 samples and asserts `max_observed <= 40.0` (i.e., `noise_range * 2.0`).

Stub-no-op outcome: SURVIVES even with `random_offset` replaced by `return 0.0`. More importantly, the assertion is tautological by clamp boundary: even without the stub, the `clampf` makes `|sample| <= noise_range * 2.0` a structural guarantee. The test asserts what the production code's last line proves by construction.

Action: delete. The clamp upper bound is part of the function's signature, and reading the one-line `clampf` confirms it. `test_noise_produces_nonzero_values` covers the meaningful property (the function actually does something), and `test_noise_zero_returns_zero` covers the zero-range early-return. A 1000-iteration sampler that asserts the clamp boundary has no testable failure mode.

### `tests/unit/paddle/test_paddle_ai_math.gd:72`, `test_noise_produces_nonzero_values`

Production effect: same `random_offset`; test loops 100 samples and asserts at least 50 are nonzero.

Stub-no-op outcome: FAILS as expected (constant 0 produces 0 nonzero samples; the `assert_gt(_, 50)` fires).

Action: keep, no change.

### `tests/unit/paddle/test_paddle_auto_play.gd:76,86,115,130,134`, reaction-delay tests

Production effect: reaction-delay ring-buffer; `reaction_delay_frames` is 12, so the tests loop `frames + 1` times. The post-loop assertions check positional response to position changes inside / outside the delay window.

Stub-no-op outcome: FAILS (paddle velocity stays 0; `assert_gt(velocity.y, 0)` fires).

Action: keep, no change. Loops are short, bounded by the configured delay, and the assertions are positional, not bound-only.

### `tests/unit/paddle/test_partner_ai_controller.gd:46`, helper `_run_frames`

Used by `test_moves_toward_*`, `test_drifts_*`, `test_noise_*`. Each calling test asserts a positional or noise property; all fail with `_track()` stubbed (velocity.y stays 0). Not tautological.

Action: keep, no change.

### `tests/unit/paddle/test_timeout_controller.gd:68`, `_drive_until`

Production effect: state-machine driver; loops up to `MAX_STEPS`, breaking on a `predicate` Callable matching `_at_state(target)`. Already a deterministic seam (stops on the predicate, not after N iterations); the N cap is a safety bound.

Stub-no-op outcome: would FAIL (state never reaches target so the predicate is never true; calling tests `assert_true(reached)`).

Action: keep, no change.

### `tests/unit/items/test_cadence.gd:100,131,144`, repeated event triggers

Production effect: cap-stacking and cap-reset tests; loop N times calling `process_event(&"on_max_speed_reached")` and assert cap state. Not sim loops; each iteration is an explicit event.

Action: keep, no change.

### `tests/unit/items/test_martha_effects.gd:74,84,94`, repeated hit counts

Production effect: emit `paddle_hit` N times then `missed`, assert volley-count behaviour. Not a sim loop; each iteration is an explicit signal emit.

Action: keep, no change.

### `tests/integration/test_timeout_blocks_autoplay_drive.gd:81`, `test_paddle_reaches_equip_pose_under_autoplay_pressure`

Production effect: break-on-state-reached pattern (same shape as `_drive_until`). Asserts state at end.

Stub-no-op outcome: would FAIL (state never reaches AT_EQUIP_POSE). Not tautological.

Action: keep, no change.

## Totals

Candidates audited: 11 active sim-loop or N-iteration patterns. Several short loops (Cadence stacking, Martha volley count, ball streaks) were inspected and dismissed as event-driven, not simulation.

Kept (survived stub-no-op or already deterministic): 7.

Rewritten with tautology guard: 5 (`test_oscillate_stat_stays_within_amplitude`, `test_oscillate_stat_scales_range_by_level`, `test_unregister_stops_oscillation`, `test_autoplay_speed_never_exceeds_configured_scale`, `test_speed_never_exceeds_configured_scale`).

Deleted: 1 (`test_noise_bounded_by_two_sigma`, tautological by `clampf` boundary).

## Suite timing

Before sweep: 2.019s (669 tests, 1813 asserts).
After sweep: 2.01s (668 tests, 1517 asserts).

The assertion count drop is mostly from collapsing two 300-iteration per-frame assertion loops into single-extremum sampler calls in `test_event_dispatch.gd`, plus the deleted noise-bound test.
