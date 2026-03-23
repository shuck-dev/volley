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

Don't call `_on_paddle_hit()` — emit the signal instead: `_paddle.paddle_hit.emit()`.

### Physics nodes need the scene tree

`RigidBody2D.linear_velocity` doesn't work until the node is in the tree. Always `add_child_autofree()` before setting velocity. Set `gravity_scale = 0.0` to prevent drift during `await` pauses.

### Unit vs integration

- **Unit tests** test one component's public methods or verify signal routing by emitting signals directly (`_paddle.paddle_hit.emit()`).
- **Integration tests** drive the system through its entry points (`_paddle.on_ball_hit()`) and verify the full chain.

## Known gaps

The physics dispatch path (`body_entered` -> `_on_body_entered` -> duck-typed method call) is not covered by automated tests. It requires real physics collisions and is intentionally left as a manual QA item — it's two lines that rarely change.

## CI

Tests run on every push to non-main branches via `.github/workflows/test.yml`. The `logs/` directory must be created before running GUT (`mkdir -p logs`) to prevent a crash from GUT's file logger.
