# Testing Guidelines

This project uses [GUT 9.x](https://github.com/bitwes/Gut) for testing, run via `godot --headless`.

## Structure

```
tests/
├── unit/           # Pure-logic tests: no Node, no scene tree, no stub
└── integration/    # Core-loop tests driven through simulated user input
```

## Principles

### Unit tests are pure logic only

A unit test exercises a function or a `RefCounted`/static class in isolation: math, save-dict round-trips, state-machine transition tables, parsing. No `Node`, no `add_child_autofree()`, no scene tree, no stub, no signal wiring. If the behaviour under test needs a node in the tree to mean anything, it isn't a unit test, it belongs in `tests/integration/` (see below) or it isn't worth automating.

Node-based tests found few real regressions relative to their maintenance cost: they broke on refactors that didn't change behaviour, needed constant stub upkeep, and were slow enough to shape how the suite could grow. The trade favors fewer, sturdier tests over broad node-wiring coverage.

```gdscript
func test_apex_below_ceiling_returns_arc_bend() -> void:
	assert_almost_eq(ArcMath.arc_acceleration(300.0, ARC_HEIGHT_MAX), ArcMath.ARC_BEND, 0.001)
```

### Integration tests drive core loops through simulated user input

An integration test exercises a real player-facing loop (drag a ball, press a paddle key, load a save) by simulating the actual input the player produces, an `InputEventMouseButton`/`InputEventMouseMotion` pushed through `Input.parse_input_event` or the viewport, not a direct call to the controller method that would normally handle that input. Driving `_drag.attempt_release(...)` or `_manager.take(...)` directly tests the same code the real input handler would reach, but it stops proving the wiring between input and effect actually holds; that's the coverage integration tests exist for.

Build these around a real scene (or the smallest slice of one that reproduces the loop), real nodes, `add_child_autofree()`. This is where node instantiation belongs.

### Test observable outcomes, not internal state

Don't access private variables (`_streak`, `_volley_count`). Test what the player or other systems can observe:

| Instead of | Test |
|---|---|
| `_paddle._streak == 3` | `hit_sound.pitch_scale == 1.15` |
| `_game._volley_count == 0` | `hud.last_count == 0` |
| `_ball._hit_cooldown > 0` | Second hit doesn't change pitch |

### Name a test by what it tests

The function name is the whole title GUT shows, so it carries the meaning.

- **Tests an internal value or mechanism, no player in sight.** Name the input and the literal result: `condition_<verb>_value`. Right for a pure-logic unit where the thing under test is the internals: `test_apex_below_ceiling_returns_arc_bend`, `test_apex_above_ceiling_exceeds_arc_bend`, `test_zero_bend_returns_zero`.
- **Tests a player-observable behaviour** (integration). Name the behaviour the player would see: `test_second_hit_does_not_change_pitch`, `test_streak_break_resets_the_counter`.

Keep the name to the input and the outcome. `test_steep_entry_bends_harder` describes a feel; `test_apex_above_ceiling_exceeds_arc_bend` says the input and the result. And follow the names already in the file: a new test matches its siblings.

### Only write tests when asked

Don't add test coverage proactively as part of an unrelated change. Write tests when the user asks for them, or when they're the explicit deliverable of the task.

## GUT feature reference

GUT 9.x is a third-party Asset Library plugin (`addons/gut/`); Godot 4 ships no built-in test framework. A test file `extends GutTest`; a test is any `func test_*` method. There are no custom display names, the function name is the title, so it carries the meaning (see "Naming" under Principles).

### Lifecycle

`before_all` / `before_each` / `after_each` / `after_all`. An inner `class X extends GutTest` is collected as its own group with its own lifecycle hooks; this is the only grouping GUT offers and it is one level deep (no nested-class nesting). Test order within a class is not guaranteed.

### Assertions

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

### Driving and waiting (integration)

`simulate(obj, times, delta)` calls `_process`/`_physics_process` a number of times with a fixed delta. For real-frame waits there are `wait_frames`, `wait_physics_frames`, `wait_seconds`, `wait_for_signal`, `wait_until`/`wait_while`. Prefer deterministic stepping over real-time waits, see Test budget below.

### Step tweens deterministically instead of awaiting real time

When a system under test runs a `Tween` to drive state, awaiting the tween's real-time duration multiplies wall-clock cost across every test that touches it. Pause the tween and advance it manually with `custom_step`, then yield one frame so chained `finished` callbacks settle before assertions.

```gdscript
var tween: Tween = _controller._walk_tween
if tween != null and tween.is_valid():
	tween.pause()
	tween.custom_step(_walk_duration + 0.001)
await get_tree().process_frame
```

### Physics nodes need the scene tree

`RigidBody2D.linear_velocity` doesn't work until the node is in the tree. Always `add_child_autofree()` before setting velocity. Set `gravity_scale = 0.0` to prevent drift during `await` pauses.

### How the suite runs

`.gutconfig.json` drives it: all of `res://tests/`, subdirs included, exit on failure. Filter a run with `-gdir` plus `-gprefix`, e.g. `-gdir=res://tests/unit/ball -gprefix=test_ball_apex`.

### A green GUT run is the authority for "does it compile", not `--check-only`

`godot --headless --check-only --script <file>` reports "Compilation failed" on any script that references an autoload singleton (`ItemManager`, `GameRules`, `Stats`) or a global `class_name`, because the isolated check loads no autoloads. The script is fine; this is an open engine bug ([godotengine/godot#111515](https://github.com/godotengine/godot/issues/111515), `--debug` even crashes on it). Validate in project context instead: a GUT run loads every script with autoloads up. When an isolated check disagrees with a green suite, trust the suite.

## Known gaps

The physics dispatch path is not covered by automated tests. It requires real physics collisions and is intentionally left as a manual QA item.

Visual rendering, sprites, and animations are not unit tested. CI does not pull LFS assets for the test job.

## Test budget

The full GUT suite is fast, and we like it that way. The rule of thumb: a new case should not push the per-case average up. Run the suite, note the wall time, add your case, run it again; if the average per test got slower, the fixture is doing too much real-time work.

The usual culprit is waiting for real frames. Swap `await get_tree().physics_frame` loops for deterministic stepping: call the controller's `_physics_process(virtual_delta)` directly with a chosen delta, advance tweens with `tween.custom_step(...)`, step the physics server with `PhysicsServer2D.step`. The production code is unchanged; the test just stops paying the wall-clock cost of waiting for real frames.

## CI

Tests run on every push to non-main branches via `.github/workflows/test.yml`. The `logs/` directory must be created before running GUT (`mkdir -p logs`) to prevent a crash from GUT's file logger.

CI is strict about output noise. The build fails on any `WARNING`, `ERROR`, `SCRIPT ERROR`, `USER WARNING`, or `USER ERROR` line in the GUT output, and on any orphan count (per-test `N Orphans` where `N > 0`) or exit-time `ObjectDB instances leaked at exit`. We are strict because leaks compound: a few orphans per test become impossible to triage later, and warnings hide real regressions in the noise.

If your change introduces a leak, fix it before pushing rather than carrying it forward. The two surfaces, per-test orphans and exit-time leaks, are independent, so it is worth checking both; grepping one will not catch the other.

There is one warning class we deliberately filter: Godot's cold-cache UID lookup, which fires on a first-run `--import` even when the project is valid. The filter lives in the workflow's `Leak gate` step and matches the warning pattern plus the paired `Failed loading resource` ERROR that follows it. The upstream Godot issues that track this are [#101677](https://github.com/godotengine/godot/issues/101677), [#115205](https://github.com/godotengine/godot/issues/115205), [#109636](https://github.com/godotengine/godot/issues/109636), and [#100228](https://github.com/godotengine/godot/issues/100228). The workaround in the project is to declare autoloads with `res://` paths rather than `uid://` paths so the import order does not depend on the cache; if you are adding a new autoload, follow that pattern and you will not trip the filter.
