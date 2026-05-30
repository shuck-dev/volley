---
name: test-efficiency
description: Patterns for keeping GUT cases sub-5ms. Read before writing or modifying any unit test that involves time, signals, or frames. Three free wins, one foot-gun, one anti-pattern list.
---

# Test efficiency

Volley's GUT suite holds the line at sub-2-second wall time across hundreds of cases. The discipline below keeps any new test under 5ms by default. Tests that wait on frames or sleeps inflate to 16ms-plus and break the line.

## Free wins (apply by default)

1. **Drive the system directly, do not wait for a frame.** State machines advance on signals: emit the driving signal. Per-frame logic exposes `_process(delta)` and `_physics_process(delta)` as ordinary virtuals: call them with a synthetic delta. A `for i in 10: node._physics_process(1.0 / 60.0)` runs ten ticks in sub-millisecond. Reach for `await get_tree().process_frame` only when the SceneTree itself is the system under test.

2. **Lift immutable fixtures to `before_all`.** `PackedScene` resources, parsed dictionaries, pre-warmed `RegEx`, asset lookups: anything read-only across cases moves out of `before_each`. The per-case cost goes from "scene load plus instance" to "instance only."

3. **Wait on the actual condition, not the clock.** Replace `await get_tree().create_timer(N).timeout` and `await wait_seconds(N)` with `await wait_for_signal(obj.signal_name, timeout_s)` or `await wait_until(func(): return obj.ready, timeout_s)`. The first returns immediately when the signal fires; the second checks a predicate. Sleeping is a floor; signal-waiting is the exact time the system needed.

## Foot-gun

**Never call `autofree` / `add_child_autofree` in `before_all`.** GUT frees `autofree`'d nodes after `after_each`, meaning anything autofree'd in `before_all` is freed after the very first test. The remaining cases see a freed reference and pass for the wrong reason or crash. If a `before_all` fixture is a `Node`, manage its lifecycle manually in `after_all`, or keep it in `before_each` with autofree. Source: https://gut.readthedocs.io/en/latest/Memory-Management.html

## Anti-patterns

- `await get_tree().create_timer(N).timeout` in any unit test. Hard floor; no early exit.
- `await wait_seconds(0.1)` as a "settle the engine" hack. Replace with the actual signal you're waiting on, or with a direct `_process` call.
- Per-case scene instantiation of a large `.tscn` when the test exercises one node. Instantiate the unit; if the scene context is required, the `PackedScene` resource itself can live in `before_all` and only the instance lives per-case.
- `add_child` onto a tree triggering autoload `_ready` chains that open files or query coupled singletons. Stub the collaborator or pre-load the data.
- `queue_free` plus `await wait_seconds(0.1)` to satisfy `assert_no_new_orphans`. Prefer plain `free()` with `autofree` when the test owns the object.
- Real `_process` chains for state machines that expose a deterministic `tick(delta)` seam. Call the seam.

## Tautology guard (non-negotiable)

After cutting an await or lifting a fixture, the test must still fail if the production listener chain breaks. Run the case mentally against a stubbed production that does nothing. If it passes, you weakened the test; revert and pick a different lever. This rule supersedes any efficiency win.

## When to crank `Engine.physics_ticks_per_second`

Almost never in unit tests. Cranking the tick rate (e.g. to 240) compresses wall-clock proportionally but mutates global engine state across cases. If you need it, set in `before_each` and reset in `after_each`, or do not mix tick-rates across the same script. The cleaner path is to eliminate the wait at the source per win #1.

## Measuring

For a one-off audit: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gjunit_xml_file=/tmp/gut.xml -gexit` then parse the JUnit XML and sort `testcase` elements by `time`. Each `<testcase>` carries a `time="0.00X"` attribute (seconds). GUT's stdout summary shows total suite time, not per-case.

## Sources

- GUT class reference (GutTest): https://gut.readthedocs.io/en/latest/class_ref/class_guttest.html
- GUT Awaiting: https://gut.readthedocs.io/en/latest/Awaiting.html
- GUT Memory Management: https://gut.readthedocs.io/en/latest/Memory-Management.html
- Godot: Idle and Physics Processing: https://docs.godotengine.org/en/stable/tutorials/scripting/idle_and_physics_processing.html
