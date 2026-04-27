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

The only stub is `hud_stub.gd` because the real HUD requires a wired-up Label node. If a dependency can be instantiated with minimal setup, use the real thing.

### Test observable outcomes, not internal state

Don't access private variables (`_streak`, `_volley_count`). Test what the player or other systems can observe:

| Instead of | Test |
|---|---|
| `_paddle._streak == 3` | `hit_sound.pitch_scale == 1.15` |
| `_game._volley_count == 0` | `hud.last_count == 0` |
| `_ball._hit_cooldown > 0` | Second hit doesn't change pitch |

### Don't call private methods

Don't call `_physics_process()` directly to advance time. Use `await get_tree().create_timer(0.25).timeout` so the engine runs real physics frames.

Don't call `_on_paddle_hit()` for routing checks; emit the signal instead: `_paddle.paddle_hit.emit()`.

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

## Real-input rule for player-facing acceptance criteria

Every player-facing AC has at least one integration test that drives the player's real input handler end-to-end. The handler is whichever of `_input`, `_unhandled_input`, or `Area2D.input_event` the production code routes through. The test seam (helpers like `start_drag()`, `attempt_release(position)`, `grab_from_rack()`) is for tuning isolation only; it cannot be the sole verification of an AC.

This rule exists because two consecutive Rides on the equip-loop drag work shipped with full green test suites and failed Josh's hands-on playtest on the same player ACs ([SH-218](https://linear.app/shuck-games/issue/SH-218), then [SH-247](https://linear.app/shuck-games/issue/SH-247) / [SH-245](https://linear.app/shuck-games/issue/SH-245)). Both rounds covered the seam; neither covered the press-drag-release the player actually performs. Naming and enforcing the rule is the fix.

The test seam is fine for: stat clamping, edge-cap branches, save round-trips, error paths the input handler delegates to. When you use the seam in those cases, leave a one-line comment naming why the real-input path is covered elsewhere.

### Canonical pattern: press-drag-release through real `InputEventMouseButton`

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
    # `pressed` → BallDragController.grab_live_ball.
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

Every integration test that exercises a player-facing AC drives the real input handler at least once. Tests that use the seam-only path are limited to tuning isolation, with the seam justified by a comment.

| File | Real-input coverage | Seam-only tests | Why seam is acceptable |
|---|---|---|---|
| `test_real_input_drag_paths.gd` | Shop press-drag-release (purchase + cancel), rack click-without-movement no-op (SH-252a), live-ball mid-rally grab to rack (SH-252b). | None. | Reference file for the canonical pattern. |
| `test_ball_regime_transitions.gd` | Scenario 7 (SH-245) drives `Area2D.input_event` for press and `_drag._input` for release. Scenarios 8 (SH-247) and 9 (SH-262) drive `Area2D.input_event` for press; Scenario 8 then releases through the seam (`attempt_release`), and Scenario 9 asserts only on the press flip and held-token takeover. | Scenarios 1–6 use `grab_from_rack`/`grab_live_ball` + `attempt_release`. | Scenarios 1–6 isolate placement state, court-edge clamping, save round-trip, and temporary-ball semantics. Scenario 7 covers the full press-drag-release path end-to-end; Scenarios 8 and 9 target the press-side flip behaviour their tickets specify, with the release seam acceptable because the end-to-end release is already covered by Scenario 7 and `test_real_input_drag_paths.gd`. |
| `test_shop_drag_drop.gd` | `test_real_press_on_shop_item_starts_drag_and_release_outside_purchases` drives `pickup_area.input_event` for press and `ShopItem._input` for release. | The pre-SH-258 unit-style tests still call `start_drag()` / `attempt_release()`. | They cover affordability gating, cancel-inside-shop, and fresh-balance assertions; the player-AC press-drag-release is covered by the real-input variant in the same file. |
| `test_shop_arrivals_inactive.gd` | `_take_from_shop` now drives `pickup_area.input_event` + `ShopItem._input`, so every rack-arrival assertion runs through real input. | None. | All player-AC paths drive real input. |
| `test_timeout_wiring.gd` | `_press()` builds an `InputEventAction` and feeds `_game._unhandled_input(event)` directly. | None. | Already on the real handler. |
| `test_event_dispatch_wiring.gd`, `test_miss_reset.gd`, `test_paddle_upgrades.gd`, `test_placement_drives_effects.gd`, `test_speed_bar_flows.gd`, `test_streak_buildup.gd` | Drive paddle-hit, miss, and placement signals directly; no mouse input is part of the AC. | All. | These ACs are about the post-hit / post-placement dispatch chain. The player's input is the racket swing, which the engine's physics dispatches via `body_entered` (covered manually, see Known gaps). |

## Known gaps

The physics dispatch path (`body_entered` -> `_on_body_entered` -> duck-typed method call) is not covered by automated tests. It requires real physics collisions and is intentionally left as a manual QA item; it's two lines that rarely change.

## CI

Tests run on every push to non-main branches via `.github/workflows/test.yml`. The `logs/` directory must be created before running GUT (`mkdir -p logs`) to prevent a crash from GUT's file logger.
