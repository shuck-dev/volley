# Reference

Stable vocabulary tables. All type fields use `StringName` (e.g. `&"always"`) for O(1) comparison and data-driven extensibility. New types require a dispatch branch in `EffectManager`; no enum changes.

## TriggerType

| Key | Fires when |
|---|---|
| `always` | On registration and on source level change |
| `on_miss` | Ball missed |
| `on_hit` | Ball hit |
| `on_personal_best` | Rally counter reaches a new personal best |
| `on_streak_start` | A streak begins |
| `on_streak_multiple` | Streak reaches a multiple of N |
| `on_streak_milestone` | Streak reaches a named milestone |
| `on_edge_hit` | Ball hits the edge of the paddle |
| `on_max_speed_reached` | Ball hits the current speed ceiling |
| `on_ball_behind_paddle` | Ball passes behind the paddle |
| `on_timer` | Repeating timer fires |
| `on_return_after_idle` | Player returns after a pause |
| `on_consolidation` | Ball tiers up (consolidation event) |

## ConditionType

| Key | Passes when |
|---|---|
| `game_state_is` | A named game state is active |
| `game_state_is_not` | A named game state is not active |
| `delay_random` | A random delay has elapsed since the trigger |
| `degradation_at` | Item degradation equals the specified value |
| `degradation_below` | Item degradation is below the specified value |

## OutcomeType

| Key | What it does |
|---|---|
| `modify_stat` | Permanent (while source is registered) stat add |
| `modify_stat_until_miss` | Additive stat delta, cleared on next miss |
| `multiply_stat_temporary` | Multiplicative stat delta, cleared on next miss |
| `spawn_ball` | Adds a temporary ball to the court |
| `clear_extra_balls` | Removes all temporary balls |
| `set_game_state` | Activates or deactivates a named game state |
| `deflect_ball` | Changes ball direction |
| `spawn_gravity_well` | Places a gravity attractor on the court |
| `intensify_gravity_well` | Spikes an existing gravity well's pull |
| `award_friendship_points` | Adds to the friendship point balance |
| `increment_degradation` | Advances item degradation by one step |
| `share_stats_with_partner` | Lifts the active partner's stats by the player's upgrade delta |
| `momentum_boost` | Adds a short burst to ball speed |
| `oscillate_stat` | Continuously varies a stat on a sine wave |
| `roll_table` | Picks one outcome from a weighted set and executes it |
| `set_ball_speed` | Overrides the current ball speed |
| `halve_streak` | Halves the current streak count |

`expand_kit_slots` is removed. Kit capacity is governed by the `kit_slots` stat and per-role rules; see [`../01-prototype/tech/06-roles.md`](../01-prototype/tech/06-roles.md).

## ModifierOp

| Key | Behaviour |
|---|---|
| `add` | Flat delta; applied first |
| `percentage` | Summed additively; applied as `(1 + total)` multiplier after add |
| `multiply` | Applied sequentially after percentage |

## ExpiryCondition

| Key | Removed when |
|---|---|
| `while_on_court` | The source leaves the court or is destroyed |
| `duration` | A timer expires after N seconds |
| `until_miss` | The next miss fires (stackable) |
| `until_state_exits` | A named game state ends |
| `until_next_trigger` | The same effect fires again |

## Stat keys

`EffectState` is key-agnostic. Game systems register base values at startup. New keys require no changes to `EffectState`.

| Key | Base value | Unit |
|---|---|---|
| `paddle_speed` | 500.0 | px/s |
| `paddle_size` | 50.0 | px |
| `paddle_size_min` | 50.0 | px |
| `ball_speed_min` | 400.0 | px/s |
| `ball_speed_max_range` | 300.0 | px/s (range above min) |
| `ball_speed_increment` | 15.0 | px/s |
| `friendship_points_per_hit` | 1.0 | friendship |
| `ball_magnetism` | 0.0 | force |
| `paddle_return_angle_max_degrees` | 0.0 | degrees |
| `ball_speed_offset` | 0.0 | px/s |
| `arena_height` | 986.0 | px |
| `soul_multiplier` | 1.0 | multiplier |

`paddle_size` is clamped to `[paddle_size_min, arena_height]` by the paddle entity. All base values are registered from `GameRules.BASE_STATS` at startup.

## Named game states

| State | Set by | Meaning |
|---|---|---|
| `frenzy` | The Stray | Multi-ball chaos mode; speed doubled; ends on miss |

## DescriptionState

Indexes into `Item.descriptions`. Tracked per item in `ProgressionData`.

| Value | Meaning |
|---|---|
| `default` | Base description |
| `power_revealed` | Power description unlocked |
| `narrative_revealed` | Narrative layer unlocked |
