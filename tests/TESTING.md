# Testing Guidelines

This project uses [GUT 9.x](https://github.com/bitwes/Gut) for testing, run via `godot --headless`.

## Structure

```
tests/
├── unit/           # Single-component tests
├── integration/    # Multi-component signal chain tests
└── stubs/          # Minimal fakes for untestable dependencies
```

## Principles

### Use real instances, not doubles

GUT `double()` has known issues in headless CI (cache bug [#491](https://github.com/bitwes/Gut/issues/491)) and doesn't properly simulate physics nodes. Use real instances with `add_child_autofree()`:

```gdscript
var _ball: RigidBody2D

func before_each() -> void:
    _ball = load("res://scripts/ball.gd").new()
    add_child_autofree(_ball)
```

### Only stub what you can't instantiate

Reach for a stub in `tests/stubs/` only when the real dependency cannot be instantiated with minimal setup: a node that needs a wired-up scene, an autoload, or a partner that records calls. Current stubs are `paddle_stub`, `ball_stub`, `autoplay_controller_stub`, `recording_partner_paddle_stub`, plus the `item_factory` and `progression_manager_factory` builders. If a dependency instantiates cleanly, use the real thing.

### Test observable outcomes, not internal state

Don't access private variables (`_streak`, `_volley_count`). Test what the player or other systems can observe:

| Instead of | Test |
|---|---|
| `_paddle._streak == 3` | `hit_sound.pitch_scale == 1.15` |
| `_game._volley_count == 0` | `hud.last_count == 0` |
| `_ball._hit_cooldown > 0` | Second hit doesn't change pitch |

### Name a test by what it tests

The function name is the whole title GUT shows, so it carries the meaning. Name it the same way you decide system-story vs user-story for a ticket: who is the actor, what do they observe.

- **Tests an internal value or mechanism, no player in sight.** Name the input and the literal result: `condition_<verb>_value`. Right for a pure-logic unit where the thing under test is the internals: `test_apex_below_ceiling_returns_arc_bend`, `test_apex_above_ceiling_exceeds_arc_bend`, `test_zero_bend_returns_zero`.
- **Tests a player-observable behaviour.** Name the behaviour the player would see: `test_second_hit_does_not_change_pitch`, `test_streak_break_resets_the_counter`. The same physics fact named at the gameplay layer takes the behaviour form; named at the return-value layer it takes the input-and-result form. The layer the test sits at decides which, not the underlying fact.

Avoid adjectives and adverbs doing felt work (`gentle`, `steep`, `harder`, `still`) and verbs that name a feeling rather than a result (`lands`, `lofts`); those are prose creep on a name that should state the input and the outcome. Match the file's existing names: a new test follows the style its siblings already use.

### Test behaviour the game can actually reach

Before keeping a test, confirm the production code it drives is reachable: something in the game calls the method (directly, or via a signal, `Callable`, or resource-named dispatch). A test of a method with no production caller is testing dead code, and the honest finding is the dead code, not a passing test. When you hit one, cut the test and remove the unused method (and any stub override of it) in the same change; verify the behaviour you thought it covered is owned by the live path and tested there.

Coverage tells the story: cutting a dead-method test drops coverage, and deleting the method brings it back, the net is the same reachable surface with less to maintain. (SH-430 found `Ball.reset_speed` and `set_speed_for_streak` this way; the real miss-reset runs through `enter_out_rest`, covered elsewhere.)

### Drive time deterministically; route through public seams

Advance a system under test by calling its `_physics_process(virtual_delta)` directly with a chosen delta rather than awaiting real frames. This is the project's standing practice for a fast suite (see Test budget below) and it is what unit tests here do. `_physics_process` is the engine's per-frame entry point, so driving it is simulating a frame, not poking private state.

For routing and wiring, go through the public seam: emit the signal (`_paddle.paddle_hit.emit()`) rather than calling a private handler like `_on_paddle_hit()`. Assert on public state or emitted signals, never on private fields (see the table above).

### Step tweens deterministically instead of awaiting real time

When a system under test runs a `Tween` to drive state, awaiting the tween's real-time duration multiplies wall-clock cost across every test that touches it. Pause the tween and advance it manually with `custom_step`, then yield one frame so chained `finished` callbacks settle before assertions. The production code is unchanged; tests still verify final position, signal emission, and signal counts.

```gdscript
var tween: Tween = _controller._walk_tween
if tween != null and tween.is_valid():
    tween.pause()
    tween.custom_step(_walk_duration + 0.001)
await get_tree().process_frame
```

This pattern lives in `tests/unit/paddle/test_timeout_controller.gd`.

### Physics nodes need the scene tree

`RigidBody2D.linear_velocity` doesn't work until the node is in the tree. Always `add_child_autofree()` before setting velocity. Set `gravity_scale = 0.0` to prevent drift during `await` pauses.

### Unit vs integration

- **Unit tests** test one component's public methods or verify signal routing by emitting signals directly (`_paddle.paddle_hit.emit()`).
- **Integration tests** drive the system through its entry points (`_paddle.on_ball_hit()`) and verify the full chain.

## GUT feature reference

GUT 9.x is a third-party Asset Library plugin (`addons/gut/`); Godot 4 ships no built-in test framework. A test file `extends GutTest`; a test is any `func test_*` method. There are no custom display names, the function name is the title, so it carries the meaning (see "Naming" under Principles).

### Lifecycle

`before_all` / `before_each` / `after_each` / `after_all`. An inner `class X extends GutTest` is collected as its own group with its own lifecycle hooks; this is the only grouping GUT offers and it is one level deep (no nested-class nesting). Test order within a class is not guaranteed.

### Assertions (the families we use)

| Family | Methods |
|---|---|
| Equality | `assert_eq`, `assert_ne`, `assert_almost_eq`, `assert_almost_ne`, `assert_same`, `assert_eq_deep` |
| Ordering | `assert_gt`, `assert_gte`, `assert_lt`, `assert_lte`, `assert_between` |
| Truth / null | `assert_true`, `assert_false`, `assert_null`, `assert_not_null` |
| Type | `assert_is`, `assert_typeof`, `assert_has_method` |
| Signals | `assert_signal_emitted`, `assert_signal_emitted_with_parameters`, `assert_signal_emit_count`, `assert_has_signal` (call `watch_signals(obj)` first) |
| Collections | `assert_has`, `assert_does_not_have` |
| Lifecycle / leaks | `assert_freed`, `assert_not_freed`, `assert_no_new_orphans` |
| Engine output | `assert_engine_error`, `assert_push_warning` (and their `_count` forms) |

Prefer the signal asserts for behaviour that other systems hear; prefer public-state equality for the rest. The accessor/property assert helpers (`assert_accessors`, `assert_property`, `assert_exports`) pin a getter/setter pair by name, which is implementation, so avoid them unless the accessor contract itself is the player-facing surface.

### Parameterized tests

For a behaviour that is one rule over a table of inputs, use `use_parameters` instead of N near-identical functions. One function runs once per row:

```gdscript
func test_fill_ratio(p = use_parameters([
    # [current, min, max, expected_ratio]
    [400.0, 400.0, 700.0, 0.0],
    [550.0, 400.0, 700.0, 0.5],
    [700.0, 400.0, 700.0, 1.0],
])):
    _bar.update_speed(p[0], p[0], p[1], p[2])
    assert_almost_eq(_fill_ratio(), p[3], 0.01)
```

This is the GUT-native answer to fragmented input-table suites; collapse those rather than copy a function per input.

### Driving and waiting

`simulate(obj, times, delta)` calls `_process`/`_physics_process` a number of times with a fixed delta. For real-frame waits there are `wait_frames`, `wait_physics_frames`, `wait_seconds`, `wait_for_signal`, `wait_until`/`wait_while`, but prefer deterministic stepping (see Test budget) over real-time waits.

### Doubling and stubbing

`double()` / `partial_double()` / `stub()` exist, but this project avoids them: `double()` has a headless-CI cache bug ([#491](https://github.com/bitwes/Gut/issues/491)) and does not simulate physics nodes. Use real instances with `add_child_autofree()`; reach for a hand-written stub in `tests/stubs/` only when a dependency cannot be instantiated cheaply.

### How the suite runs

`.gutconfig.json` drives it: all of `res://tests/`, subdirs included, exit on failure, with `tests/hooks/pre_run_hook.gd` and `post_run_hook.gd` around the run. Filter a run with `-gdir` plus `-gprefix`, e.g. `-gdir=res://tests/unit/ball -gprefix=test_ball_apex`.

### A green GUT run is the authority for "does it compile", not `--check-only`

`godot --headless --check-only --script <file>` reports "Compilation failed" on any script that references an autoload singleton (`ItemManager`, `GameRules`, `Stats`) or a global `class_name`, because the isolated check loads no autoloads. The script is fine; this is an open engine bug ([godotengine/godot#111515](https://github.com/godotengine/godot/issues/111515), `--debug` even crashes on it). Validate in project context instead: a GUT run loads every script with autoloads up, and the godotiq `validate`/`check_errors` tools do too. When an isolated check disagrees with a green suite, trust the suite.

## Real-input rule for player-facing acceptance criteria

Every player-facing AC has at least one integration test that drives the player's real input handler end-to-end. The handler is whichever of `_input`, `_unhandled_input`, or `Area2D.input_event` the production code routes through. The test seam (helpers like `start_drag()`, `attempt_release(position)`, `grab_from_rack()`) is for tuning isolation only; it cannot be the sole verification of an AC.

This rule exists because two consecutive Rides on the equip-loop drag work shipped with full green test suites and failed Josh's hands-on playtest on the same player ACs ([SH-218](https://linear.app/shuck-games/issue/SH-218), then [SH-247](https://linear.app/shuck-games/issue/SH-247) / [SH-245](https://linear.app/shuck-games/issue/SH-245)). Both rounds covered the seam; neither covered the press-drag-release the player actually performs. Naming and enforcing the rule is the fix.

The test seam is fine for: stat clamping, edge-cap branches, save round-trips, error paths the input handler delegates to. When you use the seam in those cases, leave a one-line comment naming why the real-input path is covered elsewhere.

### Standard pattern: press-drag-release through real `InputEventMouseButton`

The press routes through whichever `Area2D.input_event` signal the production scene listens to (`pickup_area.input_event` on a shop slot, `ClickArea.input_event` on a rack slot, `Ball.input_event` on a live ball). The release routes through the controller's `_input(InputEventMouseButton)` handler with the cursor position carried on the event itself. Both ends are deterministic under headless; no viewport polling involved.

Worked example (SH-247 ball-grab, lifted from `tests/integration/test_real_input_drag_paths.gd`):

```gdscript
func test_real_press_on_live_ball_then_drag_to_rack_returns_token() -> void:
    _setup_ball_drag()
    _manager.take("training_ball")
    _manager.activate("training_ball")
    var live: Ball = _reconciler.get_ball_for_key("training_ball")
    var viewport: Viewport = live.get_viewport()

    # Press on the live ball: routes through Ball._on_input_event → emits
    # `pressed` → ItemDragController.grab_live_ball.
    var press := InputEventMouseButton.new()
    press.button_index = MOUSE_BUTTON_LEFT
    press.pressed = true
    live.input_event.emit(viewport, press, 0)
    assert_true(_drag.is_dragging())

    await get_tree().process_frame
    assert_false(is_instance_valid(live), "live ball is freed during the hold")

    # Release at the rack drop target via a real mouse-up event. The drag
    # controller's _input reads the release point off the event; the cursor
    # position is whatever you put on the event.
    var release := InputEventMouseButton.new()
    release.button_index = MOUSE_BUTTON_LEFT
    release.pressed = false
    release.position = RACK_CENTER
    _drag._input(release)

    assert_false(_drag.is_dragging())
    assert_false(_manager.is_on_court("training_ball"))
```

The same shape applies to shop drag-as-purchase: press via `pickup_area.input_event`, release via `ShopItem._input`. The release event carries `event.position` in viewport coordinates, transformed through the canvas; tests passing `canvas_transform * world_point` get a deterministic release point under headless.

## Audit of `tests/integration/`

Integration tests are reserved for full player-loop completions (per `memory/feedback_integration_tests_loop_completion_only.md`): a rally, an equip cycle, a save/load round-trip, a shop-to-court spawn, a real-input drag from rack to court. Two-component glue and signal-handoff coverage lives in `tests/unit/`. Every player-facing AC drives the real input handler at least once.

| File | Loop completion(s) covered | Real-input coverage |
|---|---|---|
| `test_real_input_drag_paths.gd` | Shop press-drag-release purchase loop (SH-253), live-ball mid-rally grab → rack-return loop (SH-252b). | All cases drive `pickup_area.input_event` / `Area2D.input_event` and `_input(InputEventMouseButton)`. Reference file for the standard pattern. |
| `test_ball_regime_transitions.gd` | Rack → court spawn, court → rack regrow, rack → mid-venue OUT_REST, save/reload preserves live ball, real press-drag-release on rack (SH-245), real press on live ball mid-rally (SH-247), pre-existing scene Ball grabbable mid-rally. | SH-245 / SH-247 / SH-262 scenarios drive `Area2D.input_event`; the earlier scenarios pin placement-state outcomes that the real-input scenarios then exercise end-to-end. |
| `test_placement_drives_effects.gd` | Equipment rack → player → rack cycle, ball rack → court → rack cycle, save/reload preserves placement and running effects. | None needed; placement is data, not pointer input. |
| `test_miss_to_rest_to_regrab_preserves_identity.gd` | PLAY → OUT_REST → OUT_HELD → PLAY on a single Ball instance. | Drives the production drag-controller path. |
| `test_shop_drag_drop.gd` | Real-input shop press-drag-release (SH-253), shop-to-court ball spawn (SH-320), shop-to-venue OUT_REST spawn. | All three drive real `_input` or the production drag-controller path. |
| `test_shop_arrivals_inactive.gd` | Shop take → ball-rack arrival, shop take → gear-rack arrival, dev-panel purchase → court-spawn (ball) and gear-rack landing (equipment, kit-cap gated). | `_take_from_shop` drives `pickup_area.input_event` + `ShopItem._input`. |
| `test_timeout_blocks_autoplay_drive.gd` | SH-405 autoplay vs timeout: drive call during in-flight timeout is a no-op via `drive_blocked`. | Drives the production paddle.drive() path; timeout is real `TimeoutController`. |

## Known gaps

The physics dispatch path (`body_entered` -> `_on_body_entered` -> duck-typed method call) is not covered by automated tests. It requires real physics collisions and is intentionally left as a manual QA item; it's two lines that rarely change.

## Test budget

The full GUT suite is fast, and we like it that way. The fast feedback loop is one of the reasons working on this codebase feels light, and it only stays fast if every new case respects that. The rule of thumb: a new case should not push the per-case average up. Run the suite, note the wall time, add your case, run it again; if the average per test got slower, the fixture is doing too much real-time work.

The usual culprit is waiting for real frames. Swap `await get_tree().physics_frame` loops for deterministic stepping: call the controller's `_physics_process(virtual_delta)` directly with a chosen delta, advance tweens with `tween.custom_step(...)`, step the physics server with `PhysicsServer2D.step`. The production code is unchanged; the test just stops paying the wall-clock cost of waiting for real frames.

## CI

Tests run on every push to non-main branches via `.github/workflows/test.yml`. The `logs/` directory must be created before running GUT (`mkdir -p logs`) to prevent a crash from GUT's file logger.

CI is strict about output noise. The build fails on any `WARNING`, `ERROR`, `SCRIPT ERROR`, `USER WARNING`, or `USER ERROR` line in the GUT output, and on any orphan count (per-test `N Orphans` where `N > 0`) or exit-time `ObjectDB instances leaked at exit`. We are strict because leaks compound: a few orphans per test become impossible to triage later, and warnings hide real regressions in the noise.

If your change introduces a leak, fix it before pushing rather than carrying it forward. The two surfaces, per-test orphans and exit-time leaks, are independent, so it is worth checking both; grepping one will not catch the other.

There is one warning class we deliberately filter: Godot's cold-cache UID lookup, which fires on a first-run `--import` even when the project is valid. The filter lives in the workflow's `Leak gate` step and matches the warning pattern plus the paired `Failed loading resource` ERROR that follows it. The upstream Godot issues that track this are [#101677](https://github.com/godotengine/godot/issues/101677), [#115205](https://github.com/godotengine/godot/issues/115205), [#109636](https://github.com/godotengine/godot/issues/109636), and [#100228](https://github.com/godotengine/godot/issues/100228). The workaround in the project is to declare autoloads with `res://` paths rather than `uid://` paths so the import order does not depend on the cache; if you are adding a new autoload, follow that pattern and you will not trip the filter.
