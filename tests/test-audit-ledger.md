# Test audit ledger

The keep/cut record from the behavioural test-suite refactor (#730). The work is done; the
remaining cleanup runs refactor-as-we-go per PR, so this ledger is the reference for what to
watch for when a change is already in a test file. It records the bar, the verdicts reached
case by case, and the gaps a cut would otherwise leave silent.

## The bar

A test survives only if it asserts **player-visible behaviour**: a player verb and what the
player sees or feels. These are cut:

- Constructor-default checks (asserting a freshly-built object's field values; no player observes
  the instant an object is created).
- Private-field or private-method pokes that are not load-bearing.
- Re-assertions of a production constant or a formula the production code already owns
  (tautologies that pass by definition).
- Banned velocity-component checks (`linear_velocity.x` / `.y` / `.length()`): physics-internal,
  not player-seen.

Decisions are made case by case, in thread. When a cut would drop a behaviour that IS player-real
and is not covered elsewhere, it goes under Gaps rather than being dropped silently.

## Coverage method

Capture the covered production file's coverage before and after each suite trimmed (full suite run
with the coverage hook). A cut that drops the number took real coverage: investigate. A number that
holds means the cuts were genuinely redundant. The audit's job includes exposing dead production
code that only tests kept "covered"; when a cut reveals an uncalled method, the method goes too.

## Verdicts by file

### tests/unit/ball/test_ball.gd (13 to 4)

Kept: `increase_speed` advances tier at ceiling (the felt tier-up reset to the new floor) and the
three miss-zone signal tests (entry emits `missed`, a non-self body is ignored via the `body ==
self` guard, double-register stays idempotent). The miss path is live (registered from
`ball_tracker`, `missed` consumed by Court).

Cut as tautologies (recompute production's own `floor + n*increment` from the same Stats source):
`increase_speed_adds_increment`, `set_speed_for_streak_matches_incremental_hits`. The per-hit
increment folds straight into `speed` with no honest seam, so note-and-kill, not rewrite (see Gaps).

Cut as tautologies (set a bad value, assert the frame re-clamps it; the file's own closing comment
flagged this): `effect_processor_clamps_speed_to_tier_band`, `_clamp_floor_is_tier_floor`.

Cut as banned velocity-component check: `reset_speed_preserves_direction` (asserts
`linear_velocity.x`/`.y`).

Cut as the weaker redundant bound: `increase_speed_never_exceeds_tier_ceiling` (the tier-advance
test already pins speed landing at the new floor, which is below the ceiling).

Cut as tests of uncalled production methods (dead code then removed):
`reset_speed_returns_to_tier_zero_floor` (`reset_speed` has no production caller; the real
miss-reset is `_on_missed` to `enter_out_rest`, covered elsewhere),
`set_speed_for_streak_zero_equals_tier_floor` and `_caps_at_tier_ceiling` (`set_speed_for_streak`
has no caller). `Ball.reset_speed()` and `Ball.set_speed_for_streak()` and their stub overrides were
deleted; tests were the only thing keeping them "covered."

Coverage on `ball.gd`: 90.2% (dead covered) to 85.6% (tests cut, dead exposed) to 89.8% (dead
deleted). Real coverage essentially unchanged.

### tests/unit/ball/test_ball_apex_arc.gd

`test_ball_starts_in_play_normal`: cut, constructor-default check. The flight behaviour it gestures
at is covered by the transition tests in the same file.

`test_normal_to_arc_on_upward_cross`: kept, simplified. The behaviour is the arc transition
announced on the upward cross. Dropped the `gravity_scale == 1.0` assert (mechanism, coupled to the
state, cannot drift alone) and the redundant direct `play_state` read (the signal is a faithful
proxy). Kept the `play_state_changed` signal assert (the public contract other systems hear).

The entry-speed and relock-ramp tests in this file were cut as redundant re-tests of
`BallRelockState` through ball physics, owned by the pure unit `test_ball_relock_state.gd`. They are
moot now that the relock mechanism is removed (below).

### tests/unit/ball/test_ball_dragging_guard.gd (file deleted, 2 to 0)

Three independent reasons the file was hollow:

1. `freeze` is the engine `RigidBody2D.freeze`: a frozen body generates no contacts, so
   `body_entered` never fires on the real path. The "dragged ball ignores collision" behaviour is an
   engine guarantee, not Volley's to test.
2. The test reaches the in-code guard (`ball.gd` `if freeze: return`) only by calling private
   `_on_body_entered` directly, bypassing the impossible real path. `TESTING.md` lists this dispatch
   path under known gaps (deliberately not unit-tested).
3. The `StubPaddle` is inert: the guard returns before `body` is read, so the paddle is never
   consulted. The prop proves the test is hollow.

The unfrozen-registers-contact test was not hollow but cut for a different reason: its two halves are
owned by focused units already (`test_paddle.gd` for `on_ball_hit`, `test_ball.gd` for contact to
`increase_speed`), and the only thing it uniquely pinned is the dispatch glue, which runs end-to-end
in the integration rally paths. Production note: `ball.gd` `if freeze: return` is redundant
belt-and-braces on a non-player path; left as-is.

### tests/unit/ball/test_ball_relock_state.gd (file deleted, mechanism removed)

Walking this file case by case found all nine tests clean (real public-surface asserts on a pure
RefCounted), but the walk forced the question "what is relock for," and the answer removed the whole
mechanism. Relock captured the pre-arc speed and ramped back to it on the way out; the only thing
that drifted the speed it reconciled was engine gravity during the arc. The design call: speed is
held constant through the arc, gravity does not act above the bound, the arc is a shaped bend, not an
integrated parabola. With no drift, relock has nothing to restore.

The replacement is a math abstraction (more testable, the point of the walk): a `CourtPhysics`
resource (`scripts/core/court_physics.gd`) with `arc_gravity` and `arc_height_max` tunables and an
`arc_acceleration(entry_speed_up)` method. The apex emerges from entry speed (faster arcs higher) and
caps past `arc_height_max`. Pure-unit tested in `tests/unit/court/test_court_physics.gd` (apex
emerges, faster arcs higher, steep capped, no upward motion means no arc), no body, no ticks.

Removed: `relock_state.gd`, its test, `court_config.relock_ramp_seconds`, and all `_relock` /
`entry_speed` / `_track_arc_speed_change` / `_advance_relock_ramp` plumbing in `ball.gd`. Also
dropped the `gravity_scale == 1.0` mechanism-pin from `test_ball_state_transitions.gd` (kept the
`play_state == PLAY_ARC` behaviour assert).

Coverage: `ball.gd` 90.2% to 94.1% (relock branches gone); `court_physics.gd` 87.5% (new).

## Test-ergonomics pattern (not a model change)

The heavy ItemManager+ItemState+EconomyState+EffectManager rig in the ball test files made
ball-to-item coupling look like a smell. It is not: the design is "every owned thing is an item,"
and ball-is-an-item is the foundational, correct model. The fix is test ergonomics only.
`tests/stubs/ball_manager_stub.gd` is the four-method slice the ball calls on its manager
(`get_modifier`, `get_percentage_offset`, `process_event`), returning neutral values, sanctioned by
`TESTING.md` ("only stub what you cannot instantiate," hand-written, not a GUT double). Base-ball
tests use the stub; reserve the real ItemManager and items for tests that assert item-modified
behaviour (where the items are the test). Adopt per file as walked.

## Aggregation

A new test joins the existing `_*` sibling suite if any cover the same surface; new files only when
the surface is genuinely separate.

## Gaps (player-real behaviour a cut would leave uncovered)

- **Per-hit speed increment has no observable seam.** `increase_speed` folds `speed_increment`
  straight into `speed`; no signal or readout carries the applied delta as a first-class quantity, so
  it can only be tested by mirroring the formula and cannot be tuned by observation. The fix is
  production instrumentation (expose the applied per-hit delta), tracked as its own system story.
- **Ball play-state save/load round-trip.** Save persists each ball's `play_state` as an int; the
  round-trip (state, save, load, same state, plus the enum cast and missing-key default) is the
  player-facing concern. Verify coverage when the audit reaches `tests/unit/save/`; if uncovered,
  that is a real hole this refactor should surface.
