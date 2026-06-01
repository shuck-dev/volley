# Runtime Behaviour

## Oscillation

`oscillate_stat` is continuous, not event-driven. `EffectManager` ticks it every frame.

```
value = base + amplitude * sin(time * frequency + phase_offset)
```

Frequency and phase offset are randomised per effect instance so oscillation feels unpredictable rather than rhythmic. Amplitude scales with item level. The value updates every frame through `EffectState` like any other modifier.

## Delayed effects

Some conditions introduce a delay between trigger and outcome. `delay_random` is the current case.

`EffectManager` holds a list of pending delayed effects. Each tick it decrements their timers. If the invalidation event fires before the timer expires, the delayed effect discards. The lifecycle is:

1. Trigger fires; `delay_random` condition starts a timer.
2. Timer runs; the effect waits.
3. Timer expires; outcomes execute.
4. If a miss fires while waiting, the effect is discarded without executing.

## Roll tables

`roll_table` picks one outcome from an equally weighted set and executes it. The selection is a single random draw, not sequential evaluation.

"Long Shot Pays" is a special roll-table outcome that re-executes every other positive outcome in the table on the same roll.

## Item lifecycle as a model

**Standard items** move through owned, court-active, and inactive. Activating an item registers its effects; deactivating unregisters and cleans up. The Tinkerer can destroy an item from either court-active or inactive states.

**Degrading items** (Seven Years) extend the standard lifecycle with a degradation dimension. Each miss increments degradation. Levelling up resets it. When degradation reaches 100 the item breaks; broken items cannot be repaired, only destroyed. The broken state is derived: `degradation >= 100`.

Degradation is a stat in `EffectState`, keyed per item (`degradation:seven_years`). The `increment_degradation` outcome is a `modify_stat` call on this key. The `degradation_at` and `degradation_below` conditions query it via `get_stat`.

## Signal payload contract

`EffectManager` emits signals after executing outcomes. The presentation layer subscribes to these; it never subscribes to the raw game events directly. All signals carry `item_key` so subscribers can differentiate sources without knowing effect internals.

| Signal | Payload | When |
|---|---|---|
| `game_state_entered(state, item_key)` | `state: String`, `item_key: String` | Named game state activated |
| `game_state_exited(state, item_key)` | `state: String`, `item_key: String` | Named game state deactivated |
| `ball_spawned(item_key)` | `item_key: String` | Extra ball added to the court |
| `extra_balls_cleared(item_key)` | `item_key: String` | All extra balls removed |
| `item_buff_started(stat_key, duration, item_key)` | `stat_key: String`, `duration: float`, `item_key: String` | Temporary stat modification begins |
| `item_buff_expired(stat_key, item_key)` | `stat_key: String`, `item_key: String` | Temporary stat modification ends |
| `ball_deflected(item_key)` | `item_key: String` | Ball direction changed by an item |
| `gravity_well_spawned(position, item_key)` | `position: Vector2`, `item_key: String` | Gravity point placed on court |
| `gravity_well_intensified(item_key)` | `item_key: String` | Gravity well pull spiked |
| `roll_result(outcome_name, item_key)` | `outcome_name: String`, `item_key: String` | Roll table resolved |
