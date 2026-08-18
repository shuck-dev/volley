# Effect System Reference

Stable vocabulary for the effect system. All type keys are `StringName` for O(1) comparison and data-driven extensibility.

Cross-check against `EffectManager.process_event` for the full current dispatch table. Types listed here as "live" are dispatched by production code; "prototype ideas" are design-time entries that live in [`../01-prototype/tech/04-effect-system.md`](../01-prototype/tech/04-effect-system.md) until implementation lands.

---

## Trigger types

A trigger names when an effect fires. `EffectManager.register_source` handles `always`; `process_event` dispatches the rest.

### Live

| Key | When it fires |
|---|---|
| `always` | On registration and on level change; passive stat effects |
| `on_miss` | Player or partner misses the ball |
| `on_max_speed_reached` | Ball reaches its per-run speed ceiling |

### Prototype ideas

The types below are authored in the design but not yet dispatched by game code. They belong in `designs/01-prototype/tech/04-effect-system.md` until they land.

`on_hit`, `on_personal_best`, `on_streak_start`, `on_streak_multiple`, `on_streak_milestone`, `on_edge_hit`, `on_ball_behind_paddle`, `on_timer`, `on_return_after_idle`

---

## Outcome types

An outcome is a concrete `Outcome` subclass. Each subclass implements `apply(effect_state, source_key, level)`.

### Live

| Class | What it does | Example item |
|---|---|---|
| `StatOutcome` | Adds a permanent stat modifier (add, percentage, or multiply) | Ankle Weights (+paddle_speed) |
| `StatUntilMissOutcome` | Adds a temporary modifier, cleared on the next miss | Cadence (ceiling raise on max speed) |
| `OscillateStatOutcome` | Adds a continuous sinusoidal modifier, ticked every frame | Cadence (ball_speed_offset oscillation) |
| `HalveStreakOutcome` | Returns `halve_streak` game action; Court halves `_volley_count` | Seven Years (planned use) |
| `GameActionOutcome` | Returns an arbitrary `action_key` string to the caller | Base for game actions |

### Prototype ideas

The types below are designed but have no implementing subclass. They belong in `designs/01-prototype/tech/04-effect-system.md` until they land.

`spawn_ball`, `clear_extra_balls`, `set_game_state`, `deflect_ball`, `spawn_gravity_well`, `intensify_gravity_well`, `award_soul`, `increment_degradation`, `share_stats_with_partner`, `momentum_boost`, `roll_table`, `set_ball_speed`, `multiply_stat_temporary`

---

## Condition types

The `Condition` class exists; condition evaluation is not yet wired into `EffectManager.process_event`. All condition types are prototype ideas for now.

`game_state_is`, `game_state_is_not`, `delay_random`, `degradation_at`, `degradation_below`

---

## Modifier operations

| Key | Behaviour |
|---|---|
| `add` | Flat delta; applied first |
| `percentage` | Summed additively, applied as `(1 + total)` multiplier after add |
| `multiply` | Applied sequentially after percentage |

Resolution order: add, then percentage, then multiply. Two `+50%` modifiers give `+100%` (×2.0), not ×2.25.

---

## Stat keys

`EffectState` is key-agnostic. Base values register at startup via `GameRules`. The prototype stat register:

| Key | Base value | Unit |
|---|---|---|
| `paddle_speed` | 500.0 | px/s |
| `paddle_size` | 50.0 | px |
| `paddle_size_min` | 50.0 | px |
| `ball_speed_min` | 400.0 | px/s |
| `ball_speed_max_range` | 300.0 | px/s (range above min) |
| `ball_speed_increment` | 15.0 | px/s |
| `soul_per_hit` | 1.0 | unit |
| `paddle_return_angle_max_degrees` | 0.0 | degrees |
| `ball_speed_offset` | 0.0 | px/s |
| `arena_height` | 986.0 | px |

All base values are defined in `GameRules` and registered by `EffectManager` on `_ready()`. Game systems query `EffectManager.get_stat(key)` as the single source of truth; they never read raw base values directly.
